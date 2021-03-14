# 一、说明

　　在Cocos Creator的安卓的项目中，一般会在安卓层加入一些登录、支付、统计等第三方SDK，所以不能用Cocos Creator直接编译生成apk，一般的操作会先用Cocos Creator生成一个安卓工程，然后将安卓工程复制到另一个目录，然后安卓工程添加所需要的功能，再用Android Studio来打包apk。需要用到资源更新时，用Cocos Creator生成资源，再复制到新的安卓工程对应的资源中。  这一系列的操作每次打包都有些繁琐，但可以用脚本来完成。

* 1. 使用CocosCreator参数构建资源
* 2. 生成热更文件
* 3. 使用js脚本用熊猫在线压缩图片
* 4. gradlew命令行打包apk

# 二、环境

* Cocos Creator 2.4.3： 安装目录为 `D:\CocosDashboard\resources\.editors\Creator\2.4.3\CocosCreator.exe`
* SVN：安装了命令行模式，并添加到环境变量中
* node

# 三、步骤

## 1. 整个项目的目录布局

```bat
项目根目录
├─AutoCosos					# cocos项目
│  │  
│  ├─assets						# cocos资源
│  │  │  Scene.meta
│  │  │  Script.meta
│  │  │  Texture.meta
│  │  ├─resources 					# 所有资源文件目录
│  │  │  │  project.manifest		# 更热比对文件
│  │  │  │  project.manifest.meta
│  │  │  │  version.manifest		# 更热版本文件
│  │  │  │  version.manifest.meta
│  │  │  └─Texture  				# 资源图片文目录
│  │  │
│  │  ├─Scene 					# 场景资源
│  │  └─Script					# 脚本文件
│  │          
│  ├─build						# cocos 打包资源目录
│  │  └─jsb-link
│
├─Build							# 复制出来的安卓工程(从cocos项目->build->jsb-link复制)
│  │  .cocos-project.json
│  │  cocos-project-template.json
│  │  main.js
│  │  project.json
│  │  
│  ├─assets
│  ├─frameworks
│  ├─jsb-adapter
│  └─src
│          
└─Distribute					# 一键打包脚本目录
        config.ini				# 打包配置文件
        tinypng.js				# 压缩图片js脚本
        version_generator.js 	# 热更文件生成js脚本
        一键打包.bat
```

## 2. 配置文件说明

在发布目录下有一个config.ini的打包配置文件

```ini
; 注意，'='号二边不要加空格
[Common]

; 版本号说明，版本号格式为x.y.z。 
; x:大版本号，一般大改动时加一
; y:次版本号，一般改动后无法热更解决时加一
; z:修订版本号。自动获取，游戏版本为打包日期，资源版本为git/svn版本号，如无版本管理则用0

;游戏版本号
version=1.0

;资源版本号
res=1.0

;版本管理 none-无版本管理，git，svn
vc=git

;热更地址
update=https://dev.zengwu.com.cn/hello_world
```

## 3. 调整gradlew工程版本号

修改 安卓工程下的`proj.android-studio\app`目录中的`build.gradle`文件，使用安卓的版本号可以通过命令行传入。

```gradle
import org.apache.tools.ant.taskdefs.condition.Os

apply plugin: 'com.android.application'

// 新增代码
def vc = 1          // 从android studio进入时调试版本
def vn = "1.0"  // 从android studio进入时调试版本
if (project.hasProperty('VersionName')) {
    vn = "${VersionName}"
}

if (project.hasProperty('VersionCode')) {
    vc = "${VersionCode}".toInteger()
}
// 新增代码结束

android {
    compileSdkVersion PROP_COMPILE_SDK_VERSION.toInteger()
    buildToolsVersion PROP_BUILD_TOOLS_VERSION

    defaultConfig {
        applicationId "com.zngw.autococos"
        minSdkVersion PROP_MIN_SDK_VERSION
        targetSdkVersion PROP_TARGET_SDK_VERSION
        versionCode vc    // 修改为前面的vc变量
        versionName vn // 修改为前面的vn变量
...
其余代码未调整
```

## 4. 完整打包脚本

```bat
@echo off

::============= 打包时调整配置 ======================
:: 版本号说明，版本号格式为x.y.z。 
:: x:大版本号，一般大改动时加一
:: y:次版本号，一般改动后无法热更解决时加一
:: z:修订版本号。自动获取，游戏版本为打包日期，资源版本为svn版本号

:: 游戏版本号
set version=
:: 资源版本号
set res=
:: 热更地址
set update=
:: 版本管理
set vc=

call:readini Common version version
call:readini Common res res
call:readini Common update update
call:readini Common vc vc

set buildType=%1

::============= 环境及目录配置 ======================
:: 脚本所在目录
set root_path=%~dp0
:: 工程目录
set project_path=%root_path%..\Build\frameworks\runtime-src\proj.android-studio\
:: 资源目录
set assets_path=%root_path%..\AutoCosos

:: 工程名
set project_name=hello_world
:: 进入资源目录，找到进入文件对应的meta文件，找到里面的uuid填入startScene
set startScene=2d2f792f-a40c-49bb-a189-ed176a246e49
:: 项目中更热比对文件路径
set projectFile=%assets_path%\build\jsb-link\assets\resources\native\6c\6c72e2ae-37ff-4587-801b-6aa4aff1b0a4.manifest
:: 项目中更热版本文件路径
set versionFile=%assets_path%\build\jsb-link\assets\resources\native\06\066c7e06-dfd7-4527-ba79-a795e3b282c1.manifest 

:: cocos creator 程序所在。增加系统环境变理CcPATH:D:\CocosDashboard\resources\.editors\Creator
set cc=D:\CocosDashboard\resources\.editors\Creator\2.4.3\CocosCreator.exe
:: 生成文件
set apk=%project_path%\app\build\outputs\apk\release\%project_name%-release.apk
:: 输出目录
set out_path=%root_path%out
if not exist %out_path% md %out_path%


::============= 获取本地svn版本号为VersionCode版本 ======================
set code=0
if "%vc%" == "svn" (
	:: SVN Version
	for /f "delims=" %%i in ('svn info ../ ^| findstr "Rev:"') do set rev=%%i
	set code=%rev:~18%
) else if "%vc%" == "git" (
	for /f %%i in ('git rev-list HEAD --count') do set code=%%i
)
echo %code%

::============= 输出打包配置信息 ======================
:: 完成详细的版本号
set date=%date:~0,4%%date:~5,2%%date:~8,2%
set version=%version%.%date%
set res=%res%.%code%

:: 输出打包信息
echo 当前打包版本号为：%version% svn版本号： %code%

::============= 打包流程 ======================
:: 打包流程
:main

:: 1. 构建资源
call:ccBuild

:: 2. 生成热更文件
call:hotUpdate

:: 3. 复制资源文件
:: 脚本这里这复制assets、jsb-adapter、src这个目录的资源，main.js热更时会修改，调整后需要手动复制，脚本不自动复制
xcopy /q /s /y %assets_path%\build\jsb-link\assets %root_path%..\Build\assets
xcopy /q /s /y %assets_path%\build\jsb-link\src %root_path%..\Build\src
xcopy /q /s /y %assets_path%\build\jsb-link\jsb-adapter %root_path%..\Build\jsb-adapter

:: 4. 压缩图片
call:tinypng

:: 5. 遍历打包
call:buildApk

:: 6. 复制资源到打包目录，用于热更等
xcopy /q /s /y %root_path%..\Build\assets %out_path%\%res%\assets\
xcopy /q /s /y %root_path%..\Build\src %out_path%\%res%\src\

goto finish

::============= 以下是步骤函数 ======================
:: 读取ini配置. %~1:域，%~2:key %~3:返回的value值
:readini 
@setlocal enableextensions enabledelayedexpansion
@echo off
set file=config.ini
set area=[%~1]
set key=%~2
set currarea=
for /f "usebackq delims=" %%a in ("!file!") do (
    set ln=%%a
    if "x!ln:~0,1!"=="x[" (
        set currarea=!ln!
    ) else (
        for /f "tokens=1,2 delims==" %%b in ("!ln!") do (
            set currkey=%%b
            set currval=%%c
            if "x!area!"=="x!currarea!" (
				if "x!key!"=="x!currkey!" (
					set var=!currval!
				)
			)
        )
    )
)
(endlocal
	set "%~3=%var%"
)
goto:eof

::============= Cocos Creator构建资源======================
:ccBuild
echo 开始打包资源:%assets_path%
%cc% --path %assets_path% --build "title=%project_name%;platform=android;buildPath=./build;startScene=%startScene%;encryptJs=true;inlineSpriteFrames=true;template=link;md5Cache=false"
echo 打包资源完成
goto:eof

::============= 生成热更文件 ======================
:hotUpdate
echo 开始生成热更文件
if exist %out_path%\%res% (
	rd /s /q %out_path%\%res%
	md %out_path%\%res%
)

node version_generator.js -v %res% -u %update% -s %assets_path%/build/jsb-link/ -d %out_path%\%res%
echo copy /y %out_path%\%res%\project.manifest %projectFile%  
copy /y %out_path%\%res%\project.manifest %projectFile%  
copy /y %out_path%\%res%\version.manifest %versionFile%
echo 热更文件成生完成
goto:eof

::============= 压缩图片 ======================
:tinypng
echo 压缩图片
node ./tinypng.js -f %root_path%../Build/assets/resources/native -deep
goto:eof
::=============   gradle打包   ======================
:: 单渠道打包函数
:buildApk
echo 正在打包...
cd %project_path%

::call gradlew clean :%project_name%:assembleRelease -PVersionName=%version% -PVersionCode=%code%
call gradlew :%project_name%:assembleRelease -PVersionName=%version% -PVersionCode=%code%
if %errorlevel% == 1 (
    call:fail
)

set out=%out_path%\%project_name%.v%version%.apk
copy /y %apk% %out%
cd %root_path%

echo 打包完成

goto:eof

:: 失败
:fail
echo 打包失败
pause
exit 1

:: 完成
:finish
echo 完成打包
pause
::exit
```

## 4. 脚本中环境配置

在脚本中需要配置一些环境遍变。

### 资源目录

这里可以使用相对路径，先获取脚本所在的目录，然后设置cocos项目的相对路径，如：

```bat
set assets_path=%root_path%..\AutoCosos
```

### 工程名

项目名为Cocos Creator构建发布时的`游戏名称`，如：

```bat
set project_name=hello_world
```

### startScene场景名

找到Cocos Creator构建发布时的`初始场景`中的.fire文件，并前往所在目录，找到同名.fire.meta的文件，用文本编辑器打开，找到uuid。如：helloworld.fire.meta文件中的`uuid为2d2f792f-a40c-49bb-a189-ed176a246e49`

```bat
set startScene=2d2f792f-a40c-49bb-a189-ed176a246e49
```

### 热更版本文件发布后路径

在Cocos Creator项目中，装版本更热更文件project.manifest、 version.manifest放在了assets/resources目录下，找到对应的.meta文件，打开取出对应的uuid值。然后设置版本文件的路径，这个目录前面为 build\jsb-link\assets\resources\native，后面为uuid前二位的目录，再接uuid.manifest的文件名。如：

```bat
:: 项目中更热比对文件路径
set projectFile=%assets_path%\build\jsb-link\assets\resources\native\6c\6c72e2ae-37ff-4587-801b-6aa4aff1b0a4.manifest
:: 项目中更热版本文件路径
set versionFile=%assets_path%\build\jsb-link\assets\resources\native\06\066c7e06-dfd7-4527-ba79-a795e3b282c1.manifest 
```

# 四、打包测试

直接双击运行`一键打包.bat`就可以了。  等待生成完成，生成的文件会在脚本所在目录的out目录中

```bat
 out
    │  hello_world.v1.0.20210314.apk  # 生成apk
    │  
    └─1.0.1                           # 生成资源目录
        │  project.manifest
        │  version.manifest
        │  
        ├─assets
        └─src
```
