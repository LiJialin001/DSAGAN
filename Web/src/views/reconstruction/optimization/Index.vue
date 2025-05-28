<template>
    <div class="upload-container">
        <el-card class="upload-card">
            <template #header>
                <div class="card-header">
                    <span>潜空间优化</span>
                </div>
            </template>

            <!-- 必选参数设置 -->
            <div class="params-section">
                <h3>优化参数设置</h3>
                <el-form :model="optimParams" label-width="120px">
                    <el-form-item label="优化空间" required>
                        <el-radio-group v-model="optimParams.optimSpace">
                            <el-radio label="w">W空间</el-radio>
                            <el-radio label="w_plus">W+空间</el-radio>
                        </el-radio-group>
                    </el-form-item>
                    
                    <el-form-item label="优化轮数" required>
                        <el-input-number 
                            v-model="optimParams.epochs" 
                            :min="1" 
                            placeholder="请输入优化轮数"
                        />
                    </el-form-item>
                    
                    <!-- 相机参数 -->
                    <div class="camera-params">
                        <h4>相机参数设置</h4>
                        <div class="camera-group">
                            <div class="camera-label">图片1相机参数</div>
                            <el-form-item label="PPA" required>
                                <el-input-number 
                                    v-model="optimParams.ppa1" 
                                    :min="-180" 
                                    :max="180"
                                    :step="0.1"
                                    :precision="1"
                                    placeholder="图片1 PPA"
                                />
                            </el-form-item>
                            <el-form-item label="PSA" required>
                                <el-input-number 
                                    v-model="optimParams.psa1" 
                                    :min="-180" 
                                    :max="180"
                                    :step="0.1"
                                    :precision="1"
                                    placeholder="图片1 PSA"
                                />
                            </el-form-item>
                        </div>
                        
                        <div class="camera-group">
                            <div class="camera-label">图片2相机参数</div>
                            <el-form-item label="PPA" required>
                                <el-input-number 
                                    v-model="optimParams.ppa2" 
                                    :min="-180" 
                                    :max="180"
                                    :step="0.1"
                                    :precision="1"
                                    placeholder="图片2 PPA"
                                />
                            </el-form-item>
                            <el-form-item label="PSA" required>
                                <el-input-number 
                                    v-model="optimParams.psa2" 
                                    :min="-180" 
                                    :max="180"
                                    :step="0.1"
                                    :precision="1"
                                    placeholder="图片2 PSA"
                                />
                            </el-form-item>
                        </div>
                    </div>
                </el-form>
            </div>
            
            <!-- 可选参数设置 -->
            <div class="optional-params-section">
                <h3>可选参数设置</h3>
                <el-form :model="optionalParams" label-width="120px">
                    <el-form-item label="选用模型">
                        <el-select v-model="optionalParams.model" placeholder="请选择模型">
                            <el-option label="默认模型" value="default" />
                            <el-option label="模型1" value="model1" />
                            <el-option label="模型2" value="model2" />
                        </el-select>
                    </el-form-item>
                    <el-form-item label="输出文件夹">
                        <el-input 
                            v-model="optionalParams.outputFolder" 
                            placeholder="请输入输出文件夹名称"
                        />
                    </el-form-item>
                </el-form>
            </div>

            <!-- 文件上传区域 -->
            <div class="files-section">
                <h3>数据文件上传</h3>
                
                <!-- 图片1上传 -->
                <div class="upload-item">
                    <h4>视角1图片 <span class="required">*</span></h4>
                    <el-upload
                        class="upload-area"
                        drag
                        :action="null"
                        :auto-upload="false"
                        :on-change="(file) => handleFileChange(file, 'image1')"
                        :show-file-list="true"
                        :accept="'.jpg,.jpeg,.png'"
                        :limit="1"
                    >
                        <el-icon class="el-icon--upload"><upload-filled /></el-icon>
                        <div class="el-upload__text">
                            拖拽图片到此处或 <em>点击上传</em>
                        </div>
                        <template #tip>
                            <div class="el-upload__tip">
                                请上传第一个视角的图片，支持JPG、JPEG、PNG格式
                            </div>
                        </template>
                    </el-upload>
                </div>

                <!-- 图片2上传 -->
                <div class="upload-item">
                    <h4>视角2图片 <span class="required">*</span></h4>
                    <el-upload
                        class="upload-area"
                        drag
                        :action="null"
                        :auto-upload="false"
                        :on-change="(file) => handleFileChange(file, 'image2')"
                        :show-file-list="true"
                        :accept="'.jpg,.jpeg,.png'"
                        :limit="1"
                    >
                        <el-icon class="el-icon--upload"><upload-filled /></el-icon>
                        <div class="el-upload__text">
                            拖拽图片到此处或 <em>点击上传</em>
                        </div>
                        <template #tip>
                            <div class="el-upload__tip">
                                请上传第二个视角的图片，支持JPG、JPEG、PNG格式
                            </div>
                        </template>
                    </el-upload>
                </div>

                <!-- 用户编码文件上传（可选） -->
                <div class="upload-item">
                    <h4>用户编码文件 <span class="optional">(可选)</span></h4>
                    <el-upload
                        class="upload-area"
                        drag
                        :action="null"
                        :auto-upload="false"
                        :on-change="(file) => handleFileChange(file, 'userEncoding')"
                        :show-file-list="true"
                        :accept="'.npy'"
                        :limit="1"
                    >
                        <el-icon class="el-icon--upload"><upload-filled /></el-icon>
                        <div class="el-upload__text">
                            拖拽编码文件到此处或 <em>点击上传</em>
                        </div>
                        <template #tip>
                            <div class="el-upload__tip">
                                可选：上传用户编码文件(.npy格式)
                            </div>
                        </template>
                    </el-upload>
                </div>
            </div>

            <!-- 上传按钮 -->
            <div class="upload-actions">
                <el-button 
                    type="primary" 
                    :loading="uploading"
                    @click="handleUpload"
                    :disabled="!canUpload"
                >
                    开始优化
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
                <div class="download-actions" v-if="uploadResult.type">
                    <el-button 
                        type="primary"
                        @click="downloadArchive"
                        :disabled="!uploadResult.archiveUrl"
                    >
                        <el-icon><Download /></el-icon>
                        下载优化结果压缩包
                    </el-button>
                </div>
            </div>

            <!-- 处理信息显示 -->
            <div class="info-display" v-if="uploadResult && uploadResult.type">
                <el-card class="info-card">
                    <template #header>
                        <div class="info-header">
                            <span>优化信息</span>
                        </div>
                    </template>
                    <div class="info-content">
                        <p>优化轮数：{{ uploadResult.epochs || optimParams.epochs }} 轮</p>
                        <p>最终Loss：{{ uploadResult.finalLoss || '未知' }}</p>
                        <p>优化文件数量：{{ uploadResult.outputCount || 0 }} 个</p>
                        <p class="info-tip">提示：下载的压缩包中包含所有优化后的 .npy 文件</p>
                    </div>
                </el-card>
            </div>
        </el-card>
    </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { UploadFilled, Download } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { optimizeEmbeddings } from '@/api/reconstruction'
import { formatDownloadUrl } from '@/utils/download'

// 必选优化参数
const optimParams = ref({
    optimSpace: 'w',  // 默认选择W空间
    epochs: 100,
    ppa1: 0.0,
    psa1: 0.0,
    ppa2: 0.0,
    psa2: 0.0
})

// 可选参数
const optionalParams = ref({
    model: 'default',
    outputFolder: ''
})

// 状态变量
const uploading = ref(false)
const uploadProgress = ref(0)
const uploadStatus = ref('')
const uploadResult = ref(null)

// 文件状态
const files = ref({
    image1: null,
    image2: null,
    userEncoding: null
})

// 检查是否可以上传
const canUpload = computed(() => {
    return files.value.image1 && 
           files.value.image2 && 
           optimParams.value.optimSpace && // 确保选择了优化空间
           optimParams.value.epochs > 0 &&
           optimParams.value.ppa1 !== null && 
           optimParams.value.psa1 !== null &&
           optimParams.value.ppa2 !== null && 
           optimParams.value.psa2 !== null
})

// 处理文件选择
const handleFileChange = (file, type) => {
    if (!file) return false
    
    // 图片文件验证
    if (type === 'image1' || type === 'image2') {
        const extension = file.name.split('.').pop().toLowerCase()
        if (!['jpg', 'jpeg', 'png'].includes(extension)) {
            ElMessage.error('请上传JPG、JPEG或PNG格式的图片！')
            return false
        }
    }
    
    // 编码文件验证
    if (type === 'userEncoding') {
        const extension = file.name.split('.').pop().toLowerCase()
        if (extension !== 'npy') {
            ElMessage.error('请上传NPY格式的编码文件！')
            return false
        }
    }
    
    if (file.size > 50 * 1024 * 1024) {
        ElMessage.error('文件大小不能超过 50MB！')
        return false
    }

    files.value[type] = file
    return true
}

// 处理文件上传
const handleUpload = async () => {
    if (!canUpload.value) {
        ElMessage.warning('请先上传必要图片文件并设置正确的参数')
        return
    }

    try {
        uploading.value = true
        uploadStatus.value = ''
        uploadProgress.value = 0
        
        const formData = new FormData()
        
        // 添加必选参数
        formData.append('optimSpace', optimParams.value.optimSpace) // 添加优化空间参数
        formData.append('epochs', optimParams.value.epochs)
        formData.append('ppa1', optimParams.value.ppa1)
        formData.append('psa1', optimParams.value.psa1)
        formData.append('ppa2', optimParams.value.ppa2)
        formData.append('psa2', optimParams.value.psa2)
        
        // 添加可选参数
        if (optionalParams.value.model !== 'default') {
            formData.append('model', optionalParams.value.model)
        }
        if (optionalParams.value.outputFolder) {
            formData.append('outputFolder', optionalParams.value.outputFolder)
        }
        
        // 添加文件
        formData.append('image1', files.value.image1.raw)
        formData.append('image2', files.value.image2.raw)
        
        // 添加可选的用户编码文件
        if (files.value.userEncoding) {
            formData.append('userEncoding', files.value.userEncoding.raw)
        }
        
        const result = await optimizeEmbeddings(formData, (progressEvent) => {
            if (progressEvent.lengthComputable) {
                const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
                uploadProgress.value = Math.min(progress, 90)
            }
        })

        uploadProgress.value = 100
        uploadStatus.value = 'success'
        
        if (result.code === 200 && result.data) {
            uploadResult.value = {
                type: true,
                message: '优化完成！',
                archiveUrl: result.data.archiveUrl,
                epochs: result.data.epochs,
                finalLoss: result.data.finalLoss,
                outputCount: result.data.outputCount
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
        // 使用formatDownloadUrl处理下载地址
        const downloadUrl = formatDownloadUrl(uploadResult.value.archiveUrl)
        const response = await fetch(downloadUrl)
        const blob = await response.blob()
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `optimization_results_${new Date().getTime()}.zip`
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
    max-width: 800px;
    margin: 0 auto;
}

.card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.params-section, .optional-params-section {
    margin-bottom: 30px;
    padding: 20px;
    background-color: #f5f7fa;
    border-radius: 4px;
}

.params-section h3, .optional-params-section h3 {
    margin-top: 0;
    margin-bottom: 20px;
    color: #303133;
}

.camera-params {
    margin-top: 20px;
    border-top: 1px solid #e4e7ed;
    padding-top: 20px;
}

.camera-params h4 {
    margin-top: 0;
    margin-bottom: 16px;
    color: #606266;
}

.camera-group {
    margin-bottom: 20px;
    padding: 15px;
    background-color: #ffffff;
    border-radius: 4px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.camera-label {
    margin-bottom: 10px;
    font-weight: 500;
    color: #409EFF;
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
    display: flex;
    align-items: center;
}

.required {
    color: #F56C6C;
    margin-left: 4px;
}

.optional {
    color: #909399;
    margin-left: 4px;
    font-size: 14px;
    font-weight: normal;
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

.info-display {
    margin-top: 20px;
}

.info-card {
    background-color: #f5f7fa;
}

.info-header {
    font-weight: bold;
    color: #303133;
}

.info-content {
    padding: 10px 0;
}

.info-content p {
    margin: 8px 0;
    color: #606266;
}

.info-tip {
    margin-top: 16px;
    color: #909399;
    font-size: 14px;
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
</style>
