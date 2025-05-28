import request from '@/utils/request'

// 用于图像风格统一处理的API函数
export const multiCenterProcess = (formData, onUploadProgress) => {
    return request({
        url: '/api/multi-center/upload',
        method: 'post',
        data: formData,
        headers: {
            'Content-Type': 'multipart/form-data'
        },
        onUploadProgress
    })
}

// 测试函数
export const testMultiCenterProcess = () => {
    return request({
        url: '/api/multi-center/upload/test',
        method: 'post'
    })
} 