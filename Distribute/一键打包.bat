@echo off

::============= ���ʱ�������� ======================
:: �汾��˵�����汾�Ÿ�ʽΪx.y.z�� 
:: x:��汾�ţ�һ���Ķ�ʱ��һ
:: y:�ΰ汾�ţ�һ��Ķ����޷��ȸ����ʱ��һ
:: z:�޶��汾�š��Զ���ȡ����Ϸ�汾Ϊ������ڣ���Դ�汾Ϊsvn�汾��

:: ��Ϸ�汾��
set version=
:: ��Դ�汾��
set res=
:: �ȸ���ַ
set update=
:: �汾����
set vc=

:: ��ȡini����
call:readini Common version version
call:readini Common res res
call:readini Common update update
call:readini Common vc vc

set buildType=%1

::============= ������Ŀ¼���� ======================
:: �ű�����Ŀ¼
set root_path=%~dp0
:: ����Ŀ¼
set project_path=%root_path%..\Build\frameworks\runtime-src\proj.android-studio\
:: ��ԴĿ¼
set assets_path=%root_path%..\AutoCosos

:: ������
set project_name=hello_world
:: ������ԴĿ¼���ҵ������ļ���Ӧ��meta�ļ����ҵ������uuid����startScene
set startScene=2d2f792f-a40c-49bb-a189-ed176a246e49
:: ��Ŀ�и��ȱȶ��ļ�·��
set projectFile=%assets_path%\build\jsb-link\assets\resources\native\6c\6c72e2ae-37ff-4587-801b-6aa4aff1b0a4.manifest
:: ��Ŀ�и��Ȱ汾�ļ�·��
set versionFile=%assets_path%\build\jsb-link\assets\resources\native\06\066c7e06-dfd7-4527-ba79-a795e3b282c1.manifest 

:: cocos creator �������ڡ�����ϵͳ��������CcPATH:D:\CocosDashboard\resources\.editors\Creator
set cc=D:\CocosDashboard\resources\.editors\Creator\2.4.3\CocosCreator.exe
:: �����ļ�
set apk=%project_path%\app\build\outputs\apk\release\%project_name%-release.apk
:: ���Ŀ¼
set out_path=%root_path%out
if not exist %out_path% md %out_path%


::============= ��ȡ����svn�汾��ΪVersionCode�汾 ======================
set code=0
if "%vc%" == "svn" (
	:: SVN Version
	for /f "delims=" %%i in ('svn info ../ ^| findstr "Rev:"') do set rev=%%i
	set code=%rev:~18%
) else if "%vc%" == "git" (
	for /f %%i in ('git rev-list HEAD --count') do set code=%%i
)
echo %code%

::============= ������������Ϣ ======================
:: �����ϸ�İ汾��
set date=%date:~0,4%%date:~5,2%%date:~8,2%
set version=%version%.%date%
set res=%res%.%code%

:: ��������Ϣ
echo ��ǰ����汾��Ϊ��%version% svn�汾�ţ� %code%

::============= ������� ======================
:: �������
:main

:: 1. ������Դ
call:ccBuild

:: 2. �����ȸ��ļ�
call:hotUpdate

:: 3. ������Դ�ļ�
:: �ű������⸴��assets��jsb-adapter��src���Ŀ¼����Դ��main.js�ȸ�ʱ���޸ģ���������Ҫ�ֶ����ƣ��ű����Զ�����
xcopy /q /s /y %assets_path%\build\jsb-link\assets %root_path%..\Build\assets
xcopy /q /s /y %assets_path%\build\jsb-link\src %root_path%..\Build\src
xcopy /q /s /y %assets_path%\build\jsb-link\jsb-adapter %root_path%..\Build\jsb-adapter

:: 4. ѹ��ͼƬ
call:tinypng

:: 5. �������
call:buildApk

:: 6. ������Դ�����Ŀ¼�������ȸ���
xcopy /q /s /y %root_path%..\Build\assets %out_path%\%res%\assets\
xcopy /q /s /y %root_path%..\Build\src %out_path%\%res%\src\

goto finish

::============= �����ǲ��躯�� ======================
:: ��ȡini����. %~1:��%~2:key %~3:���ص�valueֵ
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

::============= Cocos Creator������Դ======================
:ccBuild
echo ��ʼ�����Դ:%assets_path%
%cc% --path %assets_path% --build "title=%project_name%;platform=android;buildPath=./build;startScene=%startScene%;encryptJs=true;inlineSpriteFrames=true;template=link;md5Cache=false"
echo �����Դ���
goto:eof

::============= �����ȸ��ļ� ======================
:hotUpdate
echo ��ʼ�����ȸ��ļ�
if exist %out_path%\%res% (
	rd /s /q %out_path%\%res%
	md %out_path%\%res%
)

node version_generator.js -v %res% -u %update% -s %assets_path%/build/jsb-link/ -d %out_path%\%res%
echo copy /y %out_path%\%res%\project.manifest %projectFile%  
copy /y %out_path%\%res%\project.manifest %projectFile%  
copy /y %out_path%\%res%\version.manifest %versionFile%
echo �ȸ��ļ��������
goto:eof

::============= ѹ��ͼƬ ======================
:tinypng
echo ѹ��ͼƬ
node ./tinypng.js -f %root_path%../Build/assets/resources/native -deep
goto:eof

::=============   gradle���   ======================
:: �������������
:buildApk
echo ���ڴ��...
cd %project_path%

::call gradlew clean :%project_name%:assembleRelease -PVersionName=%version% -PVersionCode=%code%
call gradlew :%project_name%:assembleRelease -PVersionName=%version% -PVersionCode=%code%
if %errorlevel% == 1 (
    call:fail
)

set out=%out_path%\%project_name%.v%version%.apk
copy /y %apk% %out%
cd %root_path%

echo ������

goto:eof

:: ʧ��
:fail
echo ���ʧ��
pause
exit 1

:: ���
:finish
echo ��ɴ��
pause
::exit