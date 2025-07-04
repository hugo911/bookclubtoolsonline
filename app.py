from flask import Flask, render_template, request, send_file, session, jsonify
from bs4 import BeautifulSoup
import spacy
import pandas as pd
import ebooklib
from ebooklib import epub
from pathlib import Path
import io
import os
import uuid
import pickle
import config
import PyPDF2
import fitz  # PyMuPDF作为备选方案

# 初始化 Flask 应用
app = Flask(__name__)
# 设置 session 密钥，这对于在生产环境中是至关重要的
app.secret_key = os.urandom(24)

# 创建临时文件存储目录
temp_dir = Path("temp_data")
temp_dir.mkdir(exist_ok=True)

# 加载 spaCy 模型并设置最大文本长度
nlp = spacy.load(config.SPACY_MODEL)
nlp.max_length = config.MAX_TEXT_LENGTH

def read_pdf_with_pypdf2(file_path):
    """使用PyPDF2从PDF文件中提取纯文本内容。"""
    text = ""
    try:
        with open(file_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            for page_num in range(len(pdf_reader.pages)):
                page = pdf_reader.pages[page_num]
                text += page.extract_text() + " "
    except Exception as e:
        print(f"PyPDF2读取PDF失败: {str(e)}")
        raise
    return text

def read_pdf_with_pymupdf(file_path):
    """使用PyMuPDF从PDF文件中提取纯文本内容（备选方案）。"""
    text = ""
    try:
        doc = fitz.open(file_path)
        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            text += page.get_text() + " "
        doc.close()
    except Exception as e:
        print(f"PyMuPDF读取PDF失败: {str(e)}")
        raise
    return text

def read_pdf(file_path):
    """从PDF文件中提取纯文本内容，优先使用PyPDF2，失败时使用PyMuPDF。"""
    try:
        # 优先使用PyPDF2
        return read_pdf_with_pypdf2(file_path)
    except Exception as e:
        print(f"PyPDF2提取失败，尝试使用PyMuPDF: {str(e)}")
        try:
            # 备选方案：使用PyMuPDF
            return read_pdf_with_pymupdf(file_path)
        except Exception as e2:
            print(f"PyMuPDF提取也失败: {str(e2)}")
            raise Exception("无法从PDF文件中提取文本内容")

def read_epub(file_path):
    """从 epub 文件中提取纯文本内容，移除 HTML 标签。"""
    book = epub.read_epub(file_path)
    text = ""
    for item in book.get_items():
        if item.get_type() == ebooklib.ITEM_DOCUMENT:
            soup = BeautifulSoup(item.get_content(), 'html.parser')
            text += soup.get_text() + " "
    return text

def process_book(book_file, wfdata_file, dict_file, rank_threshold=15000):
    """处理电子书文件（EPUB或PDF）并返回一个包含单词和翻译的 DataFrame。"""
    df = pd.read_excel(wfdata_file)
    df["WORD"] = df["WORD"].str.lower()
    df = df.drop_duplicates(subset="WORD", keep="first")

    dictdata = pd.read_csv(dict_file)
    
    # 根据文件扩展名选择合适的读取方法
    file_extension = Path(book_file).suffix.lower()
    if file_extension == '.epub':
        text = read_epub(book_file)
    elif file_extension == '.pdf':
        text = read_pdf(book_file)
    else:
        raise ValueError(f"不支持的文件格式: {file_extension}")

    doc = nlp(text)
    unique_words = set(token.lemma_.lower() for token in doc if token.is_alpha)

    book_word = pd.DataFrame(list(unique_words), columns=["WORD"])
    merged_df = pd.merge(df, book_word, how="inner", on="WORD")

    Ranked = merged_df[merged_df["RANK"] >= rank_threshold]

    batch_lookup = pd.merge(Ranked, dictdata, how="left")
    # 确保我们只选择需要的列，并处理缺失的翻译
    clear_data = batch_lookup[["WORD", "translation"]]
    clear_data['translation'] = clear_data['translation'].fillna('N/A')
    
    return clear_data

def save_words_to_file(words_df):
    """保存单词数据到临时文件并返回文件ID"""
    file_id = str(uuid.uuid4())
    file_path = temp_dir / f"{file_id}.pkl"
    
    # 使用pickle保存DataFrame
    with open(file_path, 'wb') as f:
        pickle.dump(words_df, f)
    
    return file_id

def load_words_from_file(file_id):
    """从临时文件加载单词数据"""
    if not file_id:
        return None
    
    file_path = temp_dir / f"{file_id}.pkl"
    if not file_path.exists():
        return None
    
    try:
        with open(file_path, 'rb') as f:
            return pickle.load(f)
    except Exception:
        return None

def cleanup_old_files():
    """清理超过1小时的临时文件"""
    import time
    current_time = time.time()
    for file_path in temp_dir.glob("*.pkl"):
        if current_time - file_path.stat().st_mtime > 3600:  # 1小时
            try:
                file_path.unlink()
            except Exception:
                pass

@app.route("/", methods=["GET", "POST"])
def index():
    """主页：处理文件上传并返回 JSON 响应。"""
    if request.method == "POST":
        # 清理旧文件
        cleanup_old_files()
        
        try:
            if 'book_file' not in request.files:
                return jsonify({'status': 'error', 'message': '未找到文件'}), 400
            
            book_file = request.files["book_file"]
            if book_file.filename == '' or book_file.filename is None:
                return jsonify({'status': 'error', 'message': '未选择文件'}), 400
            
            # 验证文件格式
            file_extension = Path(book_file.filename).suffix.lower()
            if file_extension not in ['.epub', '.pdf']:
                return jsonify({'status': 'error', 'message': '仅支持 EPUB 和 PDF 格式文件'}), 400
            
            # 验证文件大小（限制为50MB）
            book_file.seek(0, 2)  # 移动到文件末尾
            file_size = book_file.tell()
            book_file.seek(0)  # 重置文件指针
            
            if file_size > 50 * 1024 * 1024:  # 50MB
                return jsonify({'status': 'error', 'message': '文件大小不能超过 50MB'}), 400

            # 将上传的文件保存在临时位置
            temp_filename = f"temp_uploaded_file{file_extension}"
            book_file_path = Path(temp_filename)
            book_file.save(book_file_path)

            # 验证阈值
            rank_threshold = request.form.get("rank_threshold")
            if not rank_threshold:
                rank_threshold = 15000
            else:
                try:
                    rank_threshold = int(rank_threshold)
                    if rank_threshold < 1000 or rank_threshold > 50000:
                        return jsonify({'status': 'error', 'message': '词汇量阈值必须在 1000-50000 之间'}), 400
                except ValueError:
                    return jsonify({'status': 'error', 'message': '词汇量阈值必须是数字'}), 400

            wfdata_file = "wfdata.xlsx"
            dict_file = "dict.csv"
            
            # 检查必需文件是否存在
            if not Path(wfdata_file).exists():
                return jsonify({'status': 'error', 'message': '词汇频率数据文件不存在'}), 500
            
            if not Path(dict_file).exists():
                return jsonify({'status': 'error', 'message': '翻译词典文件不存在'}), 500

            result_df = process_book(book_file_path, wfdata_file, dict_file, rank_threshold)
            
            if result_df is None or len(result_df) == 0:
                return jsonify({'status': 'error', 'message': '未找到符合条件的词汇，请尝试降低阈值'}), 400
            
            # 将结果保存到文件而不是session
            file_id = save_words_to_file(result_df)
            session['words_file_id'] = file_id

            # 返回成功状态和单词数量
            return jsonify({
                'status': 'success', 
                'count': len(result_df),
                'message': f'成功提取 {len(result_df)} 个词汇'
            })
            
        except Exception as e:
            # 记录错误日志
            print(f"处理文件时发生错误: {str(e)}")
            return jsonify({'status': 'error', 'message': '处理文件时发生错误，请重试'}), 500
        
        finally:
            # 清理临时文件
            try:
                if Path("temp_uploaded_file.epub").exists():
                    Path("temp_uploaded_file.epub").unlink()
                if Path("temp_uploaded_file.pdf").exists():
                    Path("temp_uploaded_file.pdf").unlink()
            except:
                pass

    return render_template("index.html")

@app.route("/download")
def download():
    """为 Anki/Quizlet 生成并提供 CSV 文件下载。"""
    try:
        file_id = session.get('words_file_id')
        words_df = load_words_from_file(file_id)
        
        if words_df is None:
            return render_template("index.html"), 404

        # 创建一个符合 Anki/Quizlet 格式的 CSV (单词,翻译)
        output = io.StringIO()
        words_df[["WORD", "translation"]].to_csv(output, index=False, header=False)
        csv_data = output.getvalue()
        output.close()

        buffer = io.BytesIO()
        buffer.write(csv_data.encode('utf-8-sig'))  # 添加 BOM 以支持中文
        buffer.seek(0)
        
        # 生成文件名（包含时间戳）
        from datetime import datetime
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"vocabulary_deck_{timestamp}.csv"
        
        return send_file(
            buffer,
            as_attachment=True,
            download_name=filename,
            mimetype="text/csv"
        )
        
    except Exception as e:
        print(f"下载文件时发生错误: {str(e)}")
        return render_template("index.html"), 500

@app.route("/api/status")
def api_status():
    """API 状态检查"""
    return jsonify({
        'status': 'ok',
        'version': '2.0',
        'features': {
            'epub_support': True,
            'pdf_support': True,
            'multiple_languages': False,
            'max_file_size': '50MB',
            'supported_formats': ['epub', 'pdf']
        }
    })

@app.route("/api/help")
def api_help():
    """API 帮助信息"""
    return jsonify({
        'endpoints': {
            '/': 'GET: 主页, POST: 上传文件进行处理',
            '/download': 'GET: 下载生成的词汇表 CSV 文件',
            '/api/status': 'GET: 检查 API 状态',
            '/api/help': 'GET: 获取 API 帮助信息'
        },
        'upload_requirements': {
            'file_format': 'EPUB/PDF',
            'max_size': '50MB',
            'threshold_range': '1000-50000'
        }
    })

if __name__ == "__main__":
    print(f"🚀 启动 {config.APP_NAME} v{config.APP_VERSION}")
    print(f"🌐 访问地址: http://localhost:{config.PORT}")
    print(f"📚 最大文件大小: {config.MAX_FILE_SIZE // 1024 // 1024}MB")
    print(f"🔤 支持格式: {', '.join(config.ALLOWED_EXTENSIONS)}")
    app.run(host=config.HOST, port=config.PORT, debug=config.DEBUG)
