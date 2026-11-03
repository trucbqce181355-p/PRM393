// Author: Chih An (GitHub: ChangChinAn)
// UC06: Xác minh access token trực tiếp với Supabase, không tin email do client gửi.
const { GoogleAuthError } = require('./google-auth-service');

async function verifyGoogleToken(token) {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_ANON_KEY;
  if (!url || !key) throw new GoogleAuthError(503, 'google_unavailable', 'Đăng nhập Google chưa khả dụng.');
  let response;
  try {
    response = await fetch(`${url.replace(/\/+$/, '')}/auth/v1/user`, {
      headers: { apikey: key, Authorization: `Bearer ${token}` },
      signal: AbortSignal.timeout(10000),
    });
  } catch (_) {
    throw new GoogleAuthError(503, 'google_unavailable', 'Không thể kết nối dịch vụ xác thực Google.');
  }
  if (response.status === 429 || response.status >= 500) {
    throw new GoogleAuthError(503, 'google_unavailable', 'Dịch vụ xác thực Google đang bận. Vui lòng thử lại.');
  }
  if (!response.ok) throw new GoogleAuthError(401, 'invalid_google_token', 'Phiên Google không hợp lệ hoặc đã hết hạn.');
  try { return await response.json(); } catch (_) {
    throw new GoogleAuthError(503, 'google_invalid_response', 'Không thể đọc thông tin xác thực Google.');
  }
}
module.exports = { verifyGoogleToken };
