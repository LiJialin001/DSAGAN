import request from '@/utils/request'

// 用于处理图像裁剪黑边的API函数
export const processFile = (formData, onUploadProgress) => {
    return request({
        url: '/api/processing/upload',  // 后端处理接口
        method: 'post',
        data: formData,
        headers: {
            'Content-Type': 'multipart/form-data'
        },
        onUploadProgress
    })
}

// 测试函数
export const testProcess = () => {
    return request({
        url: '/api/processing/upload/test',
        method: 'post'
    })
}