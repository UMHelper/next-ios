#!/bin/bash
# 编译前将密钥注入 GeneratedSecrets.swift(base64 编码防明文直读,生成文件不入库)
set -euo pipefail

# 按构建目标选密钥文件:模拟器 → UMSecrets.local(本地联调),真机 → UMSecrets.production.local(生产)
if [[ "$PLATFORM_NAME" == *simulator* ]]; then
  SECRET_FILE="${SRCROOT}/Secrets/UMSecrets.local"
  SECRET_NAME="UMSecrets.local"
else
  SECRET_FILE="${SRCROOT}/Secrets/UMSecrets.production.local"
  SECRET_NAME="UMSecrets.production.local"
fi
OUT_FILE="${SRCROOT}/What2REG@UM/GeneratedSecrets.swift"

if [ ! -f "$SECRET_FILE" ]; then
  echo "error: 缺少 Secrets/${SECRET_NAME}。" >&2
  echo "       请执行: cp Secrets/UMSecrets.example Secrets/${SECRET_NAME}" >&2
  echo "       并填入与服务端 UM_IOS_API_SECRET 一致的密钥。" >&2
  exit 1
fi

SECRET=$(grep -v "^#" "$SECRET_FILE" | tr -d "[:space:]")
if [ -z "$SECRET" ]; then
  echo "error: Secrets/${SECRET_NAME} 中的密钥为空" >&2
  exit 1
fi

B64=$(printf "%s" "$SECRET" | base64)

mkdir -p "$(dirname "$OUT_FILE")"
cat > "$OUT_FILE" <<SWIFT
// 本文件由 scripts/inject-secret.sh 自动生成,请勿提交(gitignore)。
import Foundation

enum APISecrets {
    /// iOS 专用 API 的 HMAC 共享密钥(与服务器 UM_IOS_API_SECRET 一致)
    static var iosAPISecret: String {
        guard let data = Data(base64Encoded: "${B64}") else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
SWIFT

echo "✓ APISecrets 注入完成"
