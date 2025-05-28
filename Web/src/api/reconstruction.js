import request from '@/utils/request'

export const embedImages = (formData, onUploadProgress) => {
    return request({
        url: '/api/reconstruction/embedding/upload',
        method: 'post',
        data: formData,
        headers: {
            'Content-Type': 'multipart/form-data'
        },
        onUploadProgress
    })
}

// 新增测试用函数 - 嵌入模块测试
export const testEmbedImages = () => {
    return request({
        url: '/api/reconstruction/embedding/test',
        method: 'post'
    })
}

export const optimizeEmbeddings = (formData, onUploadProgress) => {
    return request({
        url: '/api/reconstruction/optimization/upload',
        method: 'post',
        data: formData,
        headers: {
            'Content-Type': 'multipart/form-data'
        },
        onUploadProgress
    })
}

// 新增测试用函数 - 优化模块测试
export const testOptimizeEmbeddings = () => {
    return request({
        url: '/api/reconstruction/optimization/test',
        method: 'post'
    })
}

export const reconstruct3D = (formData, onUploadProgress) => {
    return request({
        url: '/api/reconstruction/3d/upload',
        method: 'post',
        data: formData,
        headers: {
            'Content-Type': 'multipart/form-data'
        },
        onUploadProgress
    })
}

// 修改测试用函数 - 使用相同的API路径，但发送测试标记
export const testReconstruct3D = (ppa, psa) => {
    // 创建一个FormData，添加测试标记和相机参数
    const formData = new FormData();
    formData.append('isTestMode', 'true');
    
    // 添加必需的相机参数
    formData.append('ppa', ppa);
    formData.append('psa', psa);
    
    return request({
        url: '/api/reconstruction/3d/upload',
        method: 'post',
        data: formData,
        headers: {
            'Content-Type': 'multipart/form-data'
        }
    })
} 