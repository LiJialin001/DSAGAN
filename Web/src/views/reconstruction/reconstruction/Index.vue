<template>
    <div class="upload-container">
        <el-card class="upload-card">
            <template #header>
                <div class="card-header">
                    <span>三维重建</span>
                </div>
            </template>

            <!-- 文件上传区域 -->
            <div class="files-section">
                <h3>数据文件上传</h3>
                
                <!-- 编码文件上传 -->
                <div class="upload-item">
                    <h4>用户编码文件 (.npy)</h4>
                    <el-upload
                        class="upload-area"
                        drag
                        :action="null"
                        :auto-upload="false"
                        :on-change="(file) => handleFileChange(file, 'encodings')"
                        :show-file-list="true"
                        :accept="'.zip'"
                        :limit="1"
                    >
                        <el-icon class="el-icon--upload"><upload-filled /></el-icon>
                        <div class="el-upload__text">
                            拖拽压缩文件到此处或 <em>点击上传</em>
                        </div>
                        <template #tip>
                            <div class="el-upload__tip">
                                请上传包含用户.npy编码文件的ZIP压缩包
                            </div>
                        </template>
                    </el-upload>
                </div>

                <!-- 相机参数输入框 -->
                <div class="upload-item">
                    <h4>相机参数设置</h4>
                    <div class="camera-params-inputs">
                        <el-input 
                            v-model="cameraParams.ppa" 
                            type="number" 
                            placeholder="请输入ppa参数"
                            class="param-input">
                            <template #prepend>PPA</template>
                        </el-input>
                        
                        <el-input 
                            v-model="cameraParams.psa" 
                            type="number" 
                            placeholder="请输入psa参数"
                            class="param-input">
                            <template #prepend>PSA</template>
                        </el-input>
                    </div>
                    <div class="el-upload__tip">
                        请输入用于EG3D算法的相机参数值
                    </div>
                </div>
            </div>

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
                    :disabled="!testMode && !canUpload"
                >
                    开始重建
                </el-button>
            </div>

            <!-- 上传进度显示 -->
            <div class="upload-progress" v-if="uploading">
                <el-progress 
                    :percentage="uploadProgress"
                    :status="uploadStatus"
                />
            </div>

            <!-- 处理结果显示 -->
            <div class="process-result" v-if="uploadResult">
                <el-alert
                    :title="uploadResult.message"
                    :type="uploadResult.type ? 'success' : 'error'"
                    show-icon
                />
                <!-- 下载处理结果按钮 -->
                <div class="download-actions" v-if="uploadResult.type && (!testMode || (testMode && uploadResult.archiveUrl))">
                    <el-button 
                        type="primary"
                        @click="downloadArchive"
                        :disabled="!uploadResult.archiveUrl"
                    >
                        <el-icon><Download /></el-icon>
                        下载重建结果压缩包
                    </el-button>
                </div>
            </div>

            <!-- 重建结果展示 -->
            <div class="reconstruction-display" v-if="resultList.length">
                <h3>重建结果预览</h3>
                <el-row :gutter="20">
                    <el-col :span="12" v-for="(item, index) in resultList" :key="index">
                        <el-card class="result-card" shadow="hover">
                            <template #header>
                                <div class="result-card-header">
                                    <span>视角 {{ index + 1 }}</span>
                                </div>
                            </template>
                            <el-image
                                :src="item.imageUrl"
                                :preview-src-list="resultList.map(r => r.imageUrl)"
                                :initial-index="index"
                                fit="contain"
                                class="result-image"
                            >
                                <template #error>
                                    <div class="image-error">
                                        <el-icon><picture-filled /></el-icon>
                                        <span>加载失败</span>
                                    </div>
                                </template>
                            </el-image>
                            <!-- 相机参数展示 -->
                            <div class="camera-params">
                                <h4>相机参数</h4>
                                <pre>{{ JSON.stringify(item.cameraParams, null, 2) }}</pre>
                            </div>
                        </el-card>
                    </el-col>
                </el-row>
                
                <!-- 临时调试区域 - 实际使用时可以移除 -->
                <div class="debug-info" style="margin-top: 20px; padding: 15px; background: #f8f8f8; border: 1px solid #ddd; border-radius: 4px;">
                    <h4 style="margin-top: 0; color: #606266;">图片URL调试信息</h4>
                    <div v-for="(item, index) in resultList" :key="`debug-${index}`" style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px dashed #ddd;">
                        <p style="margin: 5px 0;">图片 {{index+1}} URL: <code>{{ item.imageUrl }}</code></p>
                        <div>
                            <a :href="item.imageUrl" target="_blank" style="margin-right: 10px; color: #409eff;">在新窗口打开</a>
                        </div>
                    </div>
                    <div v-if="uploadResult && uploadResult.archiveUrl">
                        <p style="margin: 5px 0;">压缩包URL: <code>{{ uploadResult.archiveUrl }}</code></p>
                    </div>
                </div>
            </div>
        </el-card>
    </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { UploadFilled, Download, PictureFilled } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { reconstruct3D, testReconstruct3D } from '@/api/reconstruction'
import { formatDownloadUrl } from '@/utils/download'

// 测试模式状态
const testMode = ref(false)

// 文件状态
const files = ref({
    encodings: null,
    cameras: null
})

// 添加相机参数状态
const cameraParams = ref({
    ppa: null,  // 默认值，可以根据需要修改
    psa: null   // 默认值，可以根据需要修改
})

// 状态变量
const uploading = ref(false)
const uploadProgress = ref(0)
const uploadStatus = ref('')
const uploadResult = ref(null)
const resultList = ref([])

// 修改检查是否可以上传的计算属性
const canUpload = computed(() => {
    return files.value.encodings && 
           cameraParams.value.ppa !== null && 
           cameraParams.value.psa !== null
})

// 处理文件选择
const handleFileChange = (file, type) => {
    const extension = file.name.split('.').pop().toLowerCase()
    
    if (extension !== 'zip') {
        ElMessage.error('请上传ZIP格式的压缩文件！')
        return false
    }
    
    if (file.size > 50 * 1024 * 1024) {
        ElMessage.error('文件大小不能超过 50MB！')
        return false
    }

    files.value[type] = file
    return true
}

// 修改上传处理函数
const handleUpload = async () => {
    if (!testMode.value && !canUpload.value) {
        ElMessage.warning('请上传编码文件并输入相机参数')
        return
    }

    try {
        uploading.value = true
        uploadStatus.value = ''
        uploadProgress.value = 0
        resultList.value = []
        
        let result;
        
        if (testMode.value) {
            // 确保参数是有效的数字
            if (isNaN(Number(cameraParams.value.ppa)) || isNaN(Number(cameraParams.value.psa))) {
                ElMessage.warning('请输入有效的相机参数');
                uploading.value = false;
                return;
            }
            
            uploadProgress.value = 50;
            // 确保传递字符串形式的参数以避免DOM属性错误
            result = await testReconstruct3D(
                String(Number(cameraParams.value.ppa)), 
                String(Number(cameraParams.value.psa))
            );
        } else {
            // 修改正常模式的上传逻辑
            const formData = new FormData()
            formData.append('encodingsFile', files.value.encodings.raw)
            // 添加相机参数 - 先转换为数字再转为字符串以确保格式正确
            formData.append('ppa', String(Number(cameraParams.value.ppa)))
            formData.append('psa', String(Number(cameraParams.value.psa)))
            
            result = await reconstruct3D(formData, (progressEvent) => {
                if (progressEvent.lengthComputable) {
                    const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
                    uploadProgress.value = Math.min(progress, 90)
                }
            })
        }

        uploadProgress.value = 100
        uploadStatus.value = 'success'
        
        if (result.code === 200 && result.data) {
            // 确保图片URL可以正确加载
            resultList.value = result.data.images.map(img => {
                let imageUrl = img.url;
                
                // 处理图片URL
                // 如果URL不是绝对路径，且不是以/uploads开头，则添加/uploads前缀
                if (imageUrl && !imageUrl.startsWith('http') && !imageUrl.startsWith('/uploads')) {
                    imageUrl = `/uploads/${imageUrl}`;
                }
                
                return {
                    imageUrl: imageUrl,
                    cameraParams: img.cameraParams
                };
            });
            
            // 同样处理下载链接
            let archiveUrl = result.data.archiveUrl;
            if (archiveUrl && !archiveUrl.startsWith('http') && !archiveUrl.startsWith('/uploads')) {
                archiveUrl = `/uploads/${archiveUrl}`;
            }
            
            uploadResult.value = {
                type: true,
                message: '重建完成！',
                archiveUrl: archiveUrl
            };

            ElMessage.success(uploadResult.value.message);
        } else {
            throw new Error('返回数据格式不正确')
        }

    } catch (error) {
        uploadStatus.value = 'exception'
        uploadResult.value = {
            type: false,
            message: '重建失败：' + (error.message || '网络错误')
        }
        ElMessage.error(uploadResult.value.message)
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
        // 使用formatDownloadUrl处理下载地址
        const downloadUrl = formatDownloadUrl(uploadResult.value.archiveUrl)
        const response = await fetch(downloadUrl)
        const blob = await response.blob()
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `reconstruction_results_${new Date().getTime()}.zip`
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        window.URL.revokeObjectURL(url)
    } catch (error) {
        ElMessage.error('下载失败：' + error.message)
    }
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

.files-section {
    margin-bottom: 30px;
}

.files-section h3 {
    margin-bottom: 20px;
    color: #303133;
}

.upload-item {
    margin-bottom: 30px;
    padding: 20px;
    background-color: #f5f7fa;
    border-radius: 4px;
}

.upload-item h4 {
    margin-top: 0;
    margin-bottom: 16px;
    color: #606266;
}

.upload-area {
    margin: 20px 0;
}

.upload-actions {
    margin-top: 30px;
    text-align: center;
}

.upload-progress {
    margin-top: 20px;
}

.process-result {
    margin-top: 20px;
}

.reconstruction-display {
    margin-top: 30px;
}

.reconstruction-display h3 {
    margin-bottom: 20px;
    color: #303133;
    text-align: center;
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

.camera-params {
    margin-top: 16px;
    padding: 16px;
    background-color: #f5f7fa;
    border-radius: 4px;
}

.camera-params h4 {
    margin: 0 0 8px;
    color: #606266;
}

.camera-params pre {
    margin: 0;
    padding: 8px;
    background-color: #fff;
    border-radius: 4px;
    font-size: 12px;
    overflow-x: auto;
}

.image-error {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 300px;
    color: #909399;
}

.image-error .el-icon {
    font-size: 24px;
    margin-bottom: 8px;
}

.download-actions {
    margin-top: 16px;
    text-align: center;
}

.download-actions .el-button {
    margin: 0 8px;
}

.el-icon {
    margin-right: 4px;
}

.camera-params-inputs {
    display: flex;
    gap: 20px;
    margin-bottom: 10px;
}

.param-input {
    width: 100%;
}
</style>
