# 生产环境配置文件

# 应用设置
APP_NAME = "EPUB/PDF 词汇提取器"
APP_VERSION = "2.1"
DEBUG = False
HOST = "0.0.0.0"
PORT = 5000

# 文件设置
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB
ALLOWED_EXTENSIONS = ['.epub', '.pdf']
TEMP_FILE_CLEANUP_HOURS = 1  # 临时文件保留时间（小时）

# 词汇设置
DEFAULT_THRESHOLD = 15000
MIN_THRESHOLD = 1000
MAX_THRESHOLD = 50000

# spaCy 设置
SPACY_MODEL = "en_core_web_sm"
MAX_TEXT_LENGTH = 2000000  # spaCy 最大文本处理长度

# 数据文件
WORD_FREQUENCY_FILE = "wfdata.xlsx"
DICTIONARY_FILE = "dict.csv"

# 输出设置
OUTPUT_ENCODING = "utf-8-sig"  # 支持中文的 CSV 编码
CSV_SEPARATOR = ","
INCLUDE_HEADER = False

# 日志设置
LOG_LEVEL = "INFO"
LOG_FILE = "logs/app.log"

# 安全设置
SECRET_KEY_FILE = "secret_key.txt"  # 在容器中生成固定的密钥
