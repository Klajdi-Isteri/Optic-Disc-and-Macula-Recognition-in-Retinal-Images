%Read Images
imds = imageDatastore("Test","FileExtensions",[".jpg",".tif"]);
img = readimage(imds,1);

%Create a gaussian filter and use it to blur the image
%(Pre-processing)
alpha = 4;
sigma=10*alpha;

kernel = fspecial('gaussian',4*sigma+1,sigma);
imgT=imfilter(img,kernel,'symmetric');

%Image processing for Optic Disc
%Convert color space from RGB to YCbCr
YCbCr = rgb2ycbcr(imgT);

%Color tresholding based on Y value (21 is the best Y found)
Y = (YCbCr(:,:,1) >= (100 + 21) ) & (YCbCr(:,:,1) <= 250);

%Performs a morphological opening doing an erosion followed by a dilation
se = strel('disk',20);
Y = imopen(Y,se);

%Calculus of centroid for Optic Disc
pod = regionprops(Y,'Centroid');
bool1 = isempty(pod);
if(bool1 == 0)
    rod=150;
    xod = pod(1).Centroid(1);
    yod = pod(1).Centroid(2);
    ang=0:0.01:2*pi; 
    xpod=rod*cos(ang);
    ypod=rod*sin(ang);
else
    xod = 0;
    yod = 0;
    xpod=1;
    ypod=1;
end   


%Image Processing for Macula
%Convert color space from RGB to YCbCr
YCbCrM = rgb2ycbcr(imgT);

%Color tresholding based on Y value (91 is the best Y found)
YM = (YCbCrM(:,:,1) <= 150 - 91);

%Performs a morphological opening doing an erosion followed by a dilation
se = strel('disk',20);
i2o = imopen(YM,se);

%Creates a void array to put the processed mask
image_thresholded = zeros(size(i2o));

%Loop over all rows and columns
for ii=1:size(i2o,1)
    for jj=1:size(i2o,2)
        
        %Get pixel value
        pixel=i2o(ii,jj);
        
          %Makes all non center's pixel equal to zero
          if (jj < round(size(i2o,2)*(1/3)) || jj > round(size(i2o,2)*(2/3))) || (ii < round(size(i2o,1)*(1/3)) || ii > round(size(i2o,1)*(2/3)))
              new_pixel=0;
          else
              new_pixel = pixel;
          end
          
          %Save new pixel value in thresholded image
          image_thresholded(ii,jj)=new_pixel;
     end
end

%Calculus of centroid for Macula
pm = regionprops(image_thresholded,'Centroid');
bool2 = isempty(pm);
if(bool2 == 0)
    rod=150;
    rm=rod*2.86;
    xm = pm(1).Centroid(1);
    ym = pm(1).Centroid(2);
    ang=0:0.01:2*pi; 
    xpm=rm*cos(ang);
    ypm=rm*sin(ang);
else
    xm = 0;
    ym = 0;
    xpm=1;
    ypm=1;
end   


%Visualization of detected Macula and Optic Disc
figure(1), imshow(img,'border','tight'), hold on, 
scatter(xm+xpm,ym+ypm,'.','MarkerEdgeAlpha',0.1, 'MarkerEdgeColor', '#5afada'),
%since the brightest part of optic disc is in the right part we left shift the centroid 
scatter(xod-(xod*0.20)+xpod,yod+ypod,'.','MarkerEdgeAlpha',0.1, 'MarkerEdgeColor', 'blue');
legend('Macula','Optic Disc');

