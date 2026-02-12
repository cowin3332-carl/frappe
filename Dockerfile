# 直接使用官方生产镜像作为基础，它已经内置了 ERPNext v16
FROM frappe/erpnext:v16

USER root
# 1. 安装构建 CRM 所需的编译工具和中文字体
RUN apt-get update && apt-get install -y \
    git \
    fonts-wqy-microhei \
    fontconfig \
    && fc-cache -fv \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe/frappe-bench

# 2. 只安装缺少的 App (CRM)
# 加上 --skip-assets 避开最耗内存的编译阶段，我们在后面统一处理
RUN bench get-app crm --branch main --skip-assets

# 3. 统一编译前端资源 (增加内存限制防止 GitHub Actions 崩溃)
# 使用 NODE_OPTIONS 限制内存占用
RUN export NODE_OPTIONS="--max-old-space-size=4096" && \
    bench build --app crm