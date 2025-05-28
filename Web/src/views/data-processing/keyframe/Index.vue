<template>
    <div class="keyframe-container">
        <el-card class="keyframe-card">
            <template #header>
                <div class="card-header">
                    <span>关键帧提取</span>
                </div>
            </template>

            <!-- 文件上传区域 -->
            <el-upload
                class="upload-area"
                drag
                :action="null"
                :auto-upload="false"
                :on-change="handleFileChange"
                :show-file-list="true"
                :accept="'.jpg,.jpeg,.png,.bmp'"
                multiple
            >
                <el-icon class="el-icon--upload"><upload-filled /></el-icon>
                <div class="el-upload__text">
                    拖拽冠脉造影图像序列到此处或 <em>点击上传</em>
                </div>
                <template #tip>
                    <div class="el-upload__tip">
                        请上传JPG、JPEG、PNG或BMP格式的图像序列
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
                    :disabled="!testMode && selectedFiles.length < 2"
                >
                    开始提取
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
                
                <!-- 关键帧显示区域 -->
                <div class="keyframes-display" v-if="uploadResult.type && uploadResult.keyframes">
                    <el-row :gutter="20">
                        <el-col :span="12">
                            <el-card class="frame-card">
                                <template #header>
                                    <div class="frame-card-header">
                                        <span>最收缩帧</span>
                                    </div>
                                </template>
                                <div class="frame-image">
                                    <el-image 
                                        :src="uploadResult.keyframes.systoleUrl" 
                                        fit="contain"
                                        :preview-src-list="[uploadResult.keyframes.systoleUrl]"
                                    >
                                        <template #error>
                                            <div class="image-error">
                                                <el-icon><picture-filled /></el-icon>
                                                <div>加载失败</div>
                                            </div>
                                        </template>
                                    </el-image>
                                </div>
                            </el-card>
                        </el-col>
                        <el-col :span="12">
                            <el-card class="frame-card">
                                <template #header>
                                    <div class="frame-card-header">
                                        <span>最舒张帧</span>
                                    </div>
                                </template>
                                <div class="frame-image">
                                    <el-image 
                                        :src="uploadResult.keyframes.diastoleUrl" 
                                        fit="contain"
                                        :preview-src-list="[uploadResult.keyframes.diastoleUrl]"
                                    >
                                        <template #error>
                                            <div class="image-error">
                                                <el-icon><picture-filled /></el-icon>
                                                <div>加载失败</div>
                                            </div>
                                        </template>
                                    </el-image>
                                </div>
                            </el-card>
                        </el-col>
                    </el-row>
                </div>
                
                <!-- 下载处理结果按钮 -->
                <div class="download-actions" v-if="uploadResult.type && uploadResult.archiveUrl">
                    <el-button 
                        type="primary"
                        @click="downloadArchive"
                    >
                        <el-icon><Download /></el-icon>
                        下载关键帧压缩包
                    </el-button>
                </div>
                
                <!-- 调试信息 -->
                <div class="debug-info" style="margin-top: 20px; padding: 15px; background: #f8f8f8; border: 1px solid #ddd; border-radius: 4px;">
                    <h4 style="margin-top: 0; color: #606266;">图片URL调试信息</h4>
                    <div style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px dashed #ddd;">
                        <p style="margin: 5px 0;">收缩帧URL: <code>{{ uploadResult.keyframes?.systoleUrl }}</code></p>
                        <div>
                            <a :href="uploadResult.keyframes?.systoleUrl" target="_blank" style="margin-right: 10px; color: #409eff;">在新窗口打开</a>
                        </div>
                    </div>
                    <div style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px dashed #ddd;">
                        <p style="margin: 5px 0;">舒张帧URL: <code>{{ uploadResult.keyframes?.diastoleUrl }}</code></p>
                        <div>
                            <a :href="uploadResult.keyframes?.diastoleUrl" target="_blank" style="margin-right: 10px; color: #409eff;">在新窗口打开</a>
                        </div>
                    </div>
                    <div v-if="uploadResult.archiveUrl" style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px dashed #ddd;">
                        <p style="margin: 5px 0;">压缩包URL: <code>{{ uploadResult.archiveUrl }}</code></p>
                    </div>
                    <div>
                        <h4 style="margin-top: 10px; color: #606266;">原始响应数据</h4>
                        <pre style="background: #fff; padding: 10px; border-radius: 4px; max-height: 300px; overflow: auto; font-size: 12px;">{{ JSON.stringify(uploadResult.originalResponse, null, 2) }}</pre>
                    </div>
                </div>
            </div>
        </el-card>
    </div>
</template>

<script setup>
import { ref } from 'vue'
import { UploadFilled, Download, PictureFilled } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { extractKeyframes, testExtractKeyframes } from '@/api/keyframe'
import { formatDownloadUrl } from '@/utils/download'

// 测试模式状态
const testMode = ref(false)

// 状态变量
const selectedFiles = ref([])
const uploading = ref(false)
const uploadProgress = ref(0)
const uploadStatus = ref('')
const uploadResult = ref(null)

// 处理文件选择
const handleFileChange = (file) => {
    const extension = file.name.split('.').pop().toLowerCase()
    
    if (!['jpg', 'jpeg', 'png', 'bmp'].includes(extension)) {
        ElMessage.error('请上传JPG、JPEG、PNG或BMP格式的图像文件！')
        return false
    }
    
    // 将文件添加到选中文件列表
    if (!selectedFiles.value.some(f => f.uid === file.uid)) {
        selectedFiles.value.push(file)
    }
    
    uploadProgress.value = 0
    uploadResult.value = null
    return true
}

// 处理文件上传
const handleUpload = async () => {
    if (!testMode.value && selectedFiles.value.length < 2) {
        ElMessage.warning('请至少上传两张图像')
        return
    }

    try {
        uploading.value = true
        uploadStatus.value = ''
        uploadProgress.value = 0
        
        let result;
        
        if (testMode.value) {
            // 使用测试模式，不需要上传文件
            uploadProgress.value = 50;
            result = await testExtractKeyframes();
        } else {
            // 正常模式，需要上传文件
            const formData = new FormData()
            
            // 添加多个图像文件
            selectedFiles.value.forEach((file, index) => {
                formData.append(`image_${index}`, file.raw)
            })
            
            result = await extractKeyframes(formData, (progressEvent) => {
                if (progressEvent.lengthComputable) {
                    const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
                    uploadProgress.value = Math.min(progress, 90)
                }
            })
        }

        uploadProgress.value = 100
        uploadStatus.value = 'success'
        
        if (result.code === 200 && result.data) {
            // 检查是否有keyframes数组
            if (result.data.keyframes && Array.isArray(result.data.keyframes) && result.data.keyframes.length >= 2) {
                // 从keyframes数组中提取收缩帧和舒张帧URL
                const systolicFrame = result.data.keyframes.find(frame => frame.url && frame.url.includes('systolic'));
                const diastolicFrame = result.data.keyframes.find(frame => frame.url && frame.url.includes('diastolic'));
                
                // 正确处理URL，保留api前缀
                let systoleUrl = systolicFrame?.url || '';
                let diastoleUrl = diastolicFrame?.url || '';
                
                // 确保URL以/uploads开头
                systoleUrl = `/uploads/${systoleUrl}`;
                diastoleUrl = `/uploads/${diastoleUrl}`;
                
                // 处理压缩包URL
                let archiveUrl = result.data.archiveUrl || '';
                archiveUrl = `/uploads/${archiveUrl}`;
                
                uploadResult.value = {
                    type: true,
                    message: '关键帧提取成功！',
                    keyframes: {
                        systoleUrl,
                        diastoleUrl
                    },
                    archiveUrl,
                    originalResponse: result.data  // 保存原始响应用于调试
                }
            } else {
                // 兼容原来的格式，以防后端返回格式改变
                let systoleUrl = result.data.systoleUrl || '';
                let diastoleUrl = result.data.diastoleUrl || '';
                
                // 确保URL以/uploads开头
                systoleUrl = `/uploads/${systoleUrl}`;
                diastoleUrl = `/uploads/${diastoleUrl}`;
                
                // 同样处理下载链接
                let archiveUrl = result.data.archiveUrl || '';
                archiveUrl = `/uploads/${archiveUrl}`;
                
                uploadResult.value = {
                    type: true,
                    message: '关键帧提取成功！',
                    keyframes: {
                        systoleUrl,
                        diastoleUrl
                    },
                    archiveUrl,
                    originalResponse: result.data  // 保存原始响应用于调试
                }
            }

            ElMessage.success(uploadResult.value.message)
        } else {
            throw new Error('返回数据格式不正确')
        }

    } catch (error) {
        uploadStatus.value = 'exception'
        uploadResult.value = {
            type: false,
            message: '处理失败：' + (error.message || '网络错误')
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
        // 直接使用URL，不做额外处理
        const downloadUrl = uploadResult.value.archiveUrl
        window.open(downloadUrl, '_blank')
    } catch (error) {
        ElMessage.error('下载失败：' + error.message)
    }
}
</script>

<style scoped>
.keyframe-container {
    padding: 20px;
}

.keyframe-card {
    margin-bottom: 20px;
}

.card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-weight: bold;
}

.upload-area {
    width: 100%;
    margin-bottom: 20px;
}

.upload-actions {
    display: flex;
    justify-content: center;
    align-items: center;
    margin: 20px 0;
    gap: 20px;
}

.upload-actions .el-switch {
    margin: 0;
}

.upload-progress {
    margin: 20px 0;
}

.process-result {
    margin-top: 20px;
}

.keyframes-display {
    margin: 20px 0;
}

.frame-card {
    margin-bottom: 20px;
    height: auto;
}

.frame-card-header {
    text-align: center;
    font-weight: bold;
}

.frame-image {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 300px;
    width: 100%;
}

.frame-image .el-image {
    max-width: 100%;
    height: auto;
    object-fit: contain;
}

.image-error {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    height: 100%;
    color: #909399;
}

.download-actions {
    display: flex;
    justify-content: center;
    margin: 20px 0;
}

.debug-info {
    margin-top: 20px;
    padding: 15px;
    background: #f8f8f8;
    border: 1px solid #ddd;
    border-radius: 4px;
}

.debug-info h4 {
    margin-top: 0;
    color: #606266;
}

.debug-info p {
    margin: 5px 0;
}

.debug-info code {
    background: #f0f0f0;
    padding: 2px 4px;
    border-radius: 4px;
}

.debug-info a {
    color: #409eff;
    text-decoration: none;
}
</style> 