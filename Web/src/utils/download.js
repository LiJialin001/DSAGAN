/**
 * 处理下载URL，确保使用正确的前缀
 * @param {string} url - 后端返回的URL路径
 * @returns {string} - 格式化后的完整URL
 */
export const formatDownloadUrl = (url) => {
    if (!url) return '';

    // 如果已经是完整URL，则直接返回
    if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
    }
    
    // 确保URL以'/'开头
    const path = url.startsWith('/') ? url : `/${url}`;
    
    // 检查路径是否已包含uploads前缀，避免重复
    if (path.startsWith('/uploads/')) {
        return `${window.location.origin}${path}`;
    } else if (path.startsWith('/api/')) {
        return `${window.location.origin}/uploads${path}`;
    } else {
        return `${window.location.origin}/uploads${path}`;
    }
}; 