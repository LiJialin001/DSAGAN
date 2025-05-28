import request from '@/utils/request'

// 定义DICOM文件上传转换的API函数
export const uploadFile = (formData, onUploadProgress) => {
    return request({
        url: '/api/extraction/upload',
        method: 'post',
        data: formData,
        headers: {
            'Content-Type': 'multipart/form-data'
        },
        onUploadProgress
    })
}

// 测试DICOM转换函数
export const testDicomConversion = () => {
    return request({
        url: '/api/extraction/upload/test',
        method: 'post'
    })
}