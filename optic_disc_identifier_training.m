%This function does a dynamic color segmentation of the images in the YCbCr
%color space to create the mask, the function tries the Y parameter over 
%all the images and creates a cost function based on the values of the 
%roundness of the region that represents the optic disc, also some constraints 
%were applied to increase the accuracy, such as the constraint on the roundness
%value.


function [cost] = optic_disc_identifier_training(Y)
 cost = 0;

 imds = imageDatastore("Training","FileExtensions",[".jpg",".tif"]);
 numImages = numel(imds.Files);
 
 for i=1:numImages
     
        img = readimage(imds,i);

        %Create a gaussian filter and use it to blur the image
        %(Pre-processing)
        alpha = 4;
        sigma=10*alpha;

        kernel = fspecial('gaussian',4*sigma+1,sigma);
        imgT = imfilter(img,kernel,'symmetric');
        figure(2),imshow(img);
        %Convert color space from RGB to YCbCr
        YCbCrD = rgb2ycbcr(imgT);
        
        %Color tresholding based on Y value
        YD = (YCbCrD(:,:,1) >= (100 + Y) ) & (YCbCrD(:,:,1) <= 250);
        
        %Performs a morphological opening doing an erosion followed by a
        %dilation
        se = strel('disk',20);
        YD = imopen(YD,se);
        
        %Takes boundaries of image
        [bound,L] = bwboundaries(YD,'noholes');
        stats = regionprops(L,'Area','Centroid');

        %Set of max value of roundness between boundaries
        m_metric = 0;

            %Loop over the boundaries
            for k = 1:length(bound)

              %Obtain (X,Y) boundary coordinates corresponding to label 'k'
              boundary = bound{k};

              %Compute a simple estimate of the object's perimeter
              delta_sq = diff(boundary).^2;    
              perimeter = sum(sqrt(sum(delta_sq,2)));

              %Obtain the area calculation corresponding to label 'k'
              area = stats(k).Area;

              %Compute the roundness metric
              metric = 4*pi*area/perimeter^2;

              %Find max value of roundness in boundaries
              if metric > m_metric
                  m_metric = metric;
              end

            end 
            
        %Constraint on shape
        if(m_metric < 0.80)
            m_metric = 0.00;
        end
        
        %Sum of all costs
        cost = cost + (1-m_metric);
        disp('Roundness: ');
        disp(m_metric);
 end
end

