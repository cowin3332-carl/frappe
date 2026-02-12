# 第一阶段：构建器
FROM frappe/bench:version-16 AS builder

WORKDIR /home/frappe/frappe-bench

# 初始化 Bench 并明确指定 v16 分支
RUN bench init --frappe-branch version-16 --skip-redis-config-generation .

# ⚠️ 这里是为你确认后的 App 安装逻辑
# ERPNext 使用 version-16 (目前最稳定的 v16 发布分支)
# CRM 使用 main (兼容 v16 的稳定生产分支)
RUN bench get-app erpnext --branch version-16 && \
    bench get-app crm --branch main

# 编译前端资源（如果是 v16，这一步会自动处理 Vue 3 的编译）
RUN bench build --app erpnext,crm

# 第二阶段：生产镜像
FROM frappe/erpnext:version-16

USER root
# 安装中文字体
RUN apt-get update && \
    apt-get install -y fonts-wqy-microhei fontconfig && \
    fc-cache -fv && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER 1000

# 拷贝构建好的 App 和站点文件
COPY --from=builder --chown=1000:1000 /home/frappe/frappe-bench/apps /home/frappe/frappe-bench/apps
COPY --from=builder --chown=1000:1000 /home/frappe/frappe-bench/sites /home/frappe/frappe-bench/sites