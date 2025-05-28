import request from '@/utils/request'

export const embedImages = (formData, onUploadProgress) => {
    return request({
        url: '/api/embedding/upload',
        method: 'post',
        data: formData,
        headers: {
            'Content-Type': 'multipart/form-data'
        },
        onUploadProgress
    })
} 