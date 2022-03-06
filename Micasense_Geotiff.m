%2022.0306 22:47
%Micasense多光谱航片写入经纬度信息，由于Micasense航片只记录图像中心点经纬度信息，并且POS(YAW,Pitch,Roll)数据记录不准确
%这里使用同时飞行时大疆H20T广角记录的POS信息，将中心点经纬度信息结合云台航向角Yaw数据将原始航片'.tif'文件写为geotiff文件
%Author:Tiandi

clc
clear all
tic;
%导入原始航片
datadir = 'G:\无人机影像处理\2021.11\SYNC0020SET\band1(578-1234)\';
filelist = dir([datadir,'*.tif']);
info = geotiffinfo('G:\无人机影像处理\2021.11\南山水库多光谱\南山水库多光谱\4_index\reflectance\南山水库多光谱_transparent_reflectance_blue.tif');
%导入航片POS数据
POS = xlsread('G:\无人机影像处理\2021.11\SYNC0020SET\南山多光谱POS(578-1234).xlsx',2);
YAW = POS(:,6);                              %航向角
LAT = POS(:,2);                              %经度
LON = POS(:,1);                              %纬度
%计算原始图片数据
hy = (479.5^2+639.5^2)^0.5;                  %图片中心点到左右顶点像素格中心点长度
H = 150;                                     %飞行相对高度
GSD = H/120*0.08;                            %计算地物分辨率
angle_1 = atan(128/96);                      %计算长宽比正切角，此时为弧度单位
angle_2 = atan(96/128);                      %计算长宽比正切角余角，此时为弧度单位
angle_1 = angle_1 * 180 /pi;
angle_2 = angle_2 * 180 /pi;
r = 6371.393*1e3;                            %地球半径
%计算并写入经纬度
k = size(filelist);
num = k(1,1);                                %确定循环长度
parfor i = 1:num
    data = imread([datadir,filelist(i).name]);        %读取航片
    
    yaw = YAW(i,1);                                          
    yaw_abs = abs(yaw);
    if yaw_abs < angle_1 && yaw_abs < 90                %北极点未过第一个角atan(L/W)
        angle_lat = angle_1 - yaw_abs;
        angle_lon = 180 - (yaw_abs + angle_1);
    elseif yaw_abs > angle_1 && yaw_abs <90             %北极点过第一个角，但航片角仍未锐角
        angle_lat = yaw_abs - angle_1;
        angle_lon = 180 - (yaw_abs + angle_1);
    elseif yaw_abs >90 && yaw_abs < (angle_2 + 180)     %北极点过第一个角且为钝角，但航片角未过第二个角180+atan(W/L)
        angle_lat = yaw_abs + angle_1 - 180;
        angle_lon = 180 - yaw_abs + angle_1;
    elseif yaw_abs > (angle_2 + 180)
        angle_lat = yaw_abs + angle_1 -180;
        angle_lon = 180 - yaw_abs + angle_1;
    end
                                                           
    angle_y = angle_lat * pi/180;                     %求图像中心到上顶点的方向角，并转化为弧度
    angle_x = angle_lon * pi/180;                     %求图像中心到左顶点的方向角，并转化为弧度
    
    lat = LAT(i,1);
    lon = LON(i,1);
    
    data_rotate = imrotate(data,-yaw);                         %旋转图片
    A = hy*GSD*cos(angle_y)/(2*pi*r/360);
    B = abs(A);
    C = hy*GSD*sin(angle_x)/(2*pi*cosd(lat)*r/360);
    D = abs(C);
    up_lat = lat + B;            %计算上顶点纬度
    low_lat = lat - B;           %计算下顶点纬度
    up_lon = lon + D;            %计算右顶点经度
    low_lon = lon - D;           %计算左顶点经度
%   data_rotate(all(data_rotate == 0,2),:) = [];               %删除全零行
%   data_rotate(:,all(data_rotate ==0,1)) = [];                %删除全零列
    data_rotate = rot90(data_rotate');
    R = georasterref('Rastersize',size(data_rotate),'Latlim',[double(low_lat) double(up_lat)],'Lonlim',[double(low_lon) double(up_lon)]);
    geotiffwrite(['C:\Users\ROOT\Desktop\航片临时处理站\南山band1_GPS2\',filelist(i).name,'.tif'],data_rotate,R);
    disp([filelist(i).name,' done!!!'])
end
toc;
disp('All  Done ！！！')
disp(['运行时间：',num2str(toc)])


