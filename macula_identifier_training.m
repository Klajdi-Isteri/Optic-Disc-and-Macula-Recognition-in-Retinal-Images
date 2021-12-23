%This function does a dynamic color segmentation of the images in the YCbCr
%color space to create the mask, the function tries the Y parameter over 
%all the images and creates a cost function based on the values of the 
%roundness of the region that represents the macula, also some constraints 
%were applied to increase the accuracy, such as the check of black or white
%pixels in all the area of interest and a constraint on the roundness
%value.


function [cost] = macula_identifier_training(Y)
 cost = 0;

 imds = imageDatastore("Training","FileExtensions",[".jpg",".tif"]);
 numImages = numel(imds.Files);
 
 for i=1:numImages
     
        img = readimage(imds,i);

        A = 0;
        B = 0;
        C = 0;
        D = 0;
        
        square = 0;

        %Create a gaussian filter and use it to blur the image
        %(Pre-processing)
        alpha = 4;
        sigma=10*alpha;

        kernel = fspecial('gaussian',4*sigma+1,sigma);
        imgT = imfilter(img,kernel,'symmetric');

        %Convert color space from RGB to YCbCr
        YCbCrM = rgb2ycbcr(imgT);
        
        %Color tresholding based on Y value
        YM = YCbCrM(:,:,1) <= (150 - Y) ;
        
        %Performs a morphological opening doing an erosion followed by a
        %dilation
        se = strel('disk',20);
        i2o = imopen(YM,se);

        %Creates a void matrix to put the future mask
        image_thresholded = (size(i2o));

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

              %Control of perimeter A,B,C,D (black perimeter)
              if (ii == round(size(i2o,1)*(1/3)) && jj >= round(size(i2o,2)*(1/3)) && jj <= round(size(i2o,2)*(2/3)))
                  A = A + pixel;
              end

              if (ii == round(size(i2o,1)*(2/3)) && jj >= round(size(i2o,2)*(1/3)) && jj <= round(size(i2o,2)*(2/3)))
                  C = C + pixel;
              end

              if (jj == round(size(i2o,2)*(1/3)) && ii >= round(size(i2o,1)*(1/3)) && ii <= round(size(i2o,1)*(2/3)))
                  D = D + pixel;
              end

              if (jj == round(size(i2o,2)*(2/3)) && ii >= round(size(i2o,1)*(1/3)) && ii <= round(size(i2o,1)*(2/3)))
                  B = B + pixel;
              end

              %Control if internal of square is not void
              if (ii > round(size(i2o,1)*(1/3)) && ii < round(size(i2o,1)*(2/3)) && jj > round(size(i2o,2)*(1/3)) && jj < round(size(i2o,2)*(2/3)))
                  square = square + pixel;
              end

              %Save new pixel value in thresholded image (mask)
              image_thresholded(ii,jj)=new_pixel;
            end
        end
        
        %Takes boundaries of image
        [bound,L] = bwboundaries(image_thresholded,'noholes');
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

            %Control of white image 
            if(A~=0 && B~=0 && C~=0 && D~=0)
                m_metric = 0.00;
            end
            
            %Control of black image
            if(square == 0)
                m_metric = 0.00;
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

