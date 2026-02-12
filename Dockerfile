# --- 第一阶段：构建器 (使用包含 Node.js 的镜像) ---
FROM frappe/erpnext:v16 AS builder

USER root
# 安装构建所需的 git 和其它工具
RUN apt-get update && apt-get install -y git && apt-get clean

USER frappe
WORKDIR /home/frappe/frappe-bench

# 1. 这里的 ERPNext 已经预装好了，我们只拉取 CRM
# 加上 --skip-assets 是为了在下一步统一编译
RUN bench get-app crm --branch main --skip-assets

# 2. 编译前端资源
# 生产镜像可能缺少 yarn/node，如果报错，我们需要确保环境变量正确
RUN bench build --app crm

# --- 第二阶段：生产镜像 ---
FROM frappe/erpnext:v16

USER root
# 安装中文字体
RUN apt-get update && \
    apt-get install -y fonts-wqy-microhei fontconfig && \
    fc-cache -fv && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 从构建器拷贝 crm 源码和编译后的静态资源
COPY --from=builder /home/frappe/frappe-bench/apps/crm /home/frappe/frappe-bench/apps/crm
# 关键：拷贝编译后的 assets
COPY --from=builder /home/frappe/frappe-bench/sites/assets /home/frappe/frappe-bench/sites/assets

USER frappe
WORKDIR /home/frappe/frappe-bench