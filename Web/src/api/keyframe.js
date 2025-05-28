import request from '@/utils/request'

// 上传图像序列并提取关键帧
export const extractKeyframes = (formData, onUploadProgress) => {
    return request({
        url: '/api/keyframe/upload',
        method: 'post',
        data: formData,
        headers: {
            'Content-Type': 'multipart/form-data'
        },
        onUploadProgress
    })
}

// 测试功能
export const testExtractKeyframes = () => {
    return request({
        url: '/api/keyframe/test',
        method: 'post'
    })
} 