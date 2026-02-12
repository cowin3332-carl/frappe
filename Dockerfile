# 第一阶段：构建器 (基于稳定的 v16 环境)
FROM frappe/erpnext:v16 AS builder

# 切换到 root 安装必要的构建工具（git, nodejs 等官方镜像已带，但保险起见更新下）
USER root
RUN apt-get update && apt-get install -y git && apt-get clean

USER frappe
WORKDIR /home/frappe/frappe-bench

# ⚠️ 修正：直接在现有的 bench 环境下获取 App
# ERPNext 分支是 version-16，CRM 是 main
RUN bench get-app erpnext --branch version-16 && \
    bench get-app crm --branch main

# 编译资源 (v16 必须步骤，否则界面会乱码或报错)
RUN bench build --app erpnext,crm

# 第二阶段：生产镜像
FROM frappe/erpnext:v16

USER root
# 加上你最需要的中文字体
RUN apt-get update && \
    apt-get install -y fonts-wqy-microhei fontconfig && \
    fc-cache -fv && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 拷贝构建好的结果
# 官方路径通常是 /home/frappe/frappe-bench/
COPY --from=builder /home/frappe/frappe-bench/apps /home/frappe/frappe-bench/apps
COPY --from=builder /home/frappe/frappe-bench/sites /home/frappe/frappe-bench/sites

USER frappe
WORKDIR /home/frappe/frappe-bench