<template>
    <div class="upload-container">
        <el-card class="upload-card">
            <template #header>
                <div class="card-header">
                    <span>DICOM文件转换</span>
                </div>
            </template>

            <!-- 文件上传区域 -->
            <el-upload
                class="upload-area"
                drag
                :action="null"
                :auto-upload="false"
                :on-change="handleFileChange"
                :on-remove="handleFileRemove"
                :show-file-list="true"
                :accept="'.dcm'"
                multiple
            >
                <el-icon class="el-icon--upload"><upload-filled /></el-icon>
                <div class="el-upload__text">
                    拖拽DICOM文件到此处或 <em>点击上传</em>
                </div>
                <template #tip>
                    <div class="el-upload__tip">
                        支持.dcm格式的DICOM医学影像文件
                    </div>
                </template>
            </el-upload>

            <!-- 上传按钮 -->
            <div class="upload-actions">
                <el-switch
                    v-model="testMode"
                    active-text="测试模式"
                    inactive-text="正常模式"
                    style="margin-right: 20px;"
                />
                <el-button 
                    type="primary" 
                    :loading="uploading"
                    @click="handleUpload"
                    :disabled="!testMode && selectedFiles.length === 0"
                >
                    开始转换
                </el-button>
            </div>

            <!-- 上传进度显示 -->
            <div class="upload-progress" v-if="uploading">
                <el-progress 
                    :percentage="uploadProgress"
                    :status="uploadStatus"
                />
            </div>

            <!-- 上传结果显示 -->
            <div class="upload-result" v-if="uploadResult">
                <el-alert
                    :title="uploadResult.message"
                    :type="uploadResult.type ? 'success' : 'error'"
                    show-icon
                />
                <!-- 下载和下一步按钮 -->
                <div class="operation-actions" v-if="uploadResult.type">
                    <el-button 
                        type="primary"
                        @click="downloadArchive"
                        :disabled="!uploadResult.archiveUrl"
                    >
                        <el-icon><Download /></el-icon>
                        下载PNG图像压缩包
                    </el-button>
                    <el-button 
                        type="success"
                        @click="goToNextStep"
                        :disabled="resultList.length === 0"
                    >
                        <el-icon><Right /></el-icon>
                        进行图像裁剪处理
                    </el-button>
                </div>
            </div>

            <!-- 图片展示区域 -->
            <div class="image-display" v-if="resultList.length">
                <h3>转换结果</h3>
                <div class="result-list">
                    <el-row :gutter="20">
                        <el-col :span="12" v-for="(item, index) in resultList" :key="index">
                            <el-card class="result-card" shadow="hover">
                                <template #header>
                                    <div class="result-card-header">
                                        <span>图像 {{ index + 1 }}</span>
                                    </div>
                                </template>
                                <el-image
                                    :src="item.imageUrl"
                                    :preview-src-list="resultList.map(r => r.imageUrl)"
                                    :initial-index="index"
                                    fit="contain"
                                    class="result-image"
                                >
                                    <template #placeholder>
                                        <div class="image-placeholder">
                                            <el-icon><Picture /></el-icon>
                                            <span>加载中...</span>
                                        </div>
                                    </template>
                                    <template #error>
                                        <div class="image-error">
                                            <el-icon><PictureFilled /></el-icon>
                                            <span>加载失败</span>
                                        </div>
                                    </template>
                                </el-image>
                            </el-card>
                        </el-col>
                    </el-row>
                </div>
                
                <!-- 调试信息 -->
                <div class="debug-info">
                    <h4>图片URL调试信息</h4>
                    <div v-for="(item, index) in resultList" :key="`debug-${index}`" class="debug-item">
                        <p>图片 {{index+1}} URL: <code>{{ item.imageUrl }}</code></p>
                        <div>
                            <a :href="item.imageUrl" target="_blank" style="margin-right: 10px;">在新窗口打开</a>
                        </div>
                    </div>
                    <div v-if="uploadResult && uploadResult.archiveUrl">
                        <p>压缩包URL: <code>{{ uploadResult.archiveUrl }}</code></p>
                    </div>
                </div>
            </div>
        </el-card>
    </div>
</template>

<script setup>
import { ref, defineEmits, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { UploadFilled, Picture, PictureFilled, Download, Right } from '@element-plus/icons-vue'
import { uploadFile, testDicomConversion } from '@/api/upload'
import { ElMessage } from 'element-plus'
import { formatDownloadUrl } from '@/utils/download'

// 声明事件
const emit = defineEmits(['step-completed'])

// 路由对象
const route = useRoute()

// 测试模式状态
const testMode = ref(false)

// 状态变量
const selectedFiles = ref([])
const uploading = ref(false)
const uploadProgress = ref(0)
const uploadStatus = ref('')
const uploadResult = ref(null)
const resultList = ref([])

// 从URL查询参数中检查是否是从下一步返回
onMounted(() => {
    if (route.query.from_next === 'true') {
        ElMessage.info('您已返回到DICOM转换步骤')
    }
})

// 处理文件选择
const handleFileChange = (file) => {
    const extension = file.name.split('.').pop().toLowerCase();
    
    if (extension !== 'dcm') {
        ElMessage.error('请上传.dcm格式的DICOM文件！');
        return false;
    }

    // 将文件添加到选中文件列表
    if (!selectedFiles.value.some(f => f.uid === file.uid)) {
        selectedFiles.value.push(file)
    }
    
    uploadProgress.value = 0;
    return true;
}

// 处理文件移除
const handleFileRemove = (file) => {
    // 从选中文件列表中移除
    selectedFiles.value = selectedFiles.value.filter(f => f.uid !== file.uid)
}

// 处理文件上传
const handleUpload = async () => {
    if (!testMode.value && selectedFiles.value.length === 0) {
        ElMessage.warning('请先选择DICOM文件')
        return
    }

    try {
        uploading.value = true
        uploadStatus.value = ''
        uploadProgress.value = 0
        resultList.value = []
        
        let result;
        
        if (testMode.value) {
            // 使用测试模式，不需要上传文件
            uploadProgress.value = 50;
            // 使用测试API
            result = await testDicomConversion();
        } else {
            const formData = new FormData()
            
            // 添加多个DICOM文件
            selectedFiles.value.forEach((file, index) => {
                formData.append(`file_${index}`, file.raw)
            })
            
            result = await uploadFile(formData, (progressEvent) => {
                if (progressEvent.lengthComputable) {
                    const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
                    uploadProgress.value = Math.min(progress, 90)
                }
            })
        }

        // 上传完成后
        uploadProgress.value = 100
        uploadStatus.value = 'success'
        
        // 处理结果
        if (result.code === 200 && result.data) {
            // 检查是否有images数组
            if (result.data.images && Array.isArray(result.data.images)) {
                resultList.value = result.data.images.map(img => {
                    let imageUrl = img.url || img;
                    
                    // 处理图片URL
                    if (typeof imageUrl === 'string') {
                        // 确保URL以/uploads开头
                        if (imageUrl.startsWith('api/')) {
                            imageUrl = `/uploads/${imageUrl}`;
                        } else if (!imageUrl.startsWith('http') && !imageUrl.startsWith('/uploads')) {
                            imageUrl = `/uploads/${imageUrl}`;
                        }
                    }
                    
                    return {
                        imageUrl: imageUrl
                    };
                });
            }
            
            // 处理压缩包URL
            let archiveUrl = result.data.archiveUrl || '';
            if (archiveUrl.startsWith('api/')) {
                archiveUrl = `/uploads/${archiveUrl}`;
            } else if (archiveUrl && !archiveUrl.startsWith('http') && !archiveUrl.startsWith('/uploads')) {
                archiveUrl = `/uploads/${archiveUrl}`;
            }
            
            uploadResult.value = {
                type: true,
                message: `成功转换 ${resultList.value.length} 张DICOM图像！`,
                archiveUrl: archiveUrl
            }

            ElMessage.success(uploadResult.value.message)
        } else {
            throw new Error('返回数据格式不正确')
        }

    } catch (error) {
        uploadStatus.value = 'exception'
        uploadResult.value = {
            type: false,
            message: '转换失败：' + (error.message || '网络错误')
        }
        resultList.value = []
        ElMessage.error(error.message || '转换失败')
    
    } finally {
        uploading.value = false
    }
}

// 下载压缩包功能
const downloadArchive = async () => {
    if (!uploadResult.value?.archiveUrl) {
        ElMessage.warning('下载链接不存在')
        return
    }

    try {
        window.open(uploadResult.value.archiveUrl, '_blank')
    } catch (error) {
        ElMessage.error('下载失败：' + error.message)
    }
}

// 前往下一步处理
const goToNextStep = () => {
    // 准备传递给下一步的数据
    const passData = {
        imageUrls: resultList.value.map(item => item.imageUrl),
        archiveUrl: uploadResult.value?.archiveUrl || ''
    }
    
    // 触发步骤完成事件，传递数据
    emit('step-completed', passData)
}
</script>

<style scoped>
.upload-container {
    padding: 20px;
}

.upload-card {
    max-width: 1200px;
    margin: 0 auto;
}

.card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.upload-area {
    margin: 20px 0;
}

.upload-actions {
    margin-top: 20px;
    text-align: center;
}

.upload-progress {
    margin-top: 20px;
}

.upload-result {
    margin-top: 20px;
}

.operation-actions {
    display: flex;
    justify-content: center;
    margin-top: 16px;
    gap: 16px;
}

.el-upload__text {
    margin-top: 10px;
}

.el-upload__text em {
    color: #409EFF;
    font-style: normal;
}

.image-display {
    margin-top: 20px;
    padding: 20px;
    background-color: #f5f7fa;
    border-radius: 4px;
}

.image-display h3 {
    margin-bottom: 20px;
    color: #303133;
    font-size: 16px;
    font-weight: bold;
    text-align: center;
}

.result-list {
    margin-top: 20px;
}

.result-card {
    margin-bottom: 20px;
}

.result-card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.result-image {
    width: 100%;
    height: 300px;
    object-fit: contain;
}

.image-placeholder, .image-error {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    height: 300px;
    color: #909399;
    background-color: #f5f7fa;
}

.image-placeholder .el-icon, .image-error .el-icon {
    font-size: 32px;
    margin-bottom: 8px;
}

/* 调试信息样式 */
.debug-info {
    margin-top: 30px;
    padding: 15px;
    background-color: #f0f9eb;
    border-radius: 4px;
    font-size: 12px;
}

.debug-info h4 {
    color: #67c23a;
    margin-bottom: 10px;
}

.debug-item {
    margin-bottom: 8px;
    padding-bottom: 8px;
    border-bottom: 1px dashed #e1e1e1;
}

.debug-item code {
    display: inline-block;
    padding: 2px 5px;
    background-color: #f0f0f0;
    border-radius: 3px;
    color: #444;
    word-break: break-all;
}
</style>