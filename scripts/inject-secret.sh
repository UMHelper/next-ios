#!/bin/bash
# 编译前将本地密钥注入 GeneratedSecrets.swift(base64 编码防明文直读,生成文件不入库)
set -euo pipefail

SECRET_FILE="${SRCROOT}/Secrets/UMSecrets.local"
OUT_FILE="${SRCROOT}/What2REG@UM/GeneratedSecrets.swift"

if [ ! -f "$SECRET_FILE" ]; then
  echo "error: 缺少 Secrets/UMSecrets.local。" >&2
  echo "       请执行: cp Secrets/UMSecrets.example Secrets/UMSecrets.local" >&2
  echo "       并填入与服务端 UM_IOS_API_SECRET 一致的密钥。" >&2
  exit 1
fi

SECRET=$(grep -v "^#" "$SECRET_FILE" | tr -d "[:space:]")
if [ -z "$SECRET" ]; then
  echo "error: Secrets/UMSecrets.local 中的密钥为空" >&2
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
