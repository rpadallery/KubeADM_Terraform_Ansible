import { Injectable } from '@nestjs/common';
import { S3Client, ListObjectsCommand, PutObjectCommand, HeadObjectCommand } from '@aws-sdk/client-s3';
import { Upload } from '@aws-sdk/lib-storage';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AppService {
  private readonly s3Client: S3Client;


  constructor(private readonly configService: ConfigService) {
    const accessKeyId = this.configService.get<string>('AWS_ACCESS_KEY_ID');
    const secretAccessKey = this.configService.get<string>('AWS_SECRET_ACCESS_KEY');
    const region = this.configService.get<string>('S3_REGION');
    
    console.log('S3_REGION:', region);
    this.s3Client = new S3Client({
      credentials: {accessKeyId, secretAccessKey},
      region,
    });
  }

  getHello(): string {
    return 'Hello World!';
  }

  async getGallery(): Promise<{ src: string }[]> {
    const Bucket = this.configService.get<string>('S3_BUCKET');

    const listObjectsParams = {
      Bucket,
    };

    const response = await this.s3Client.send(new ListObjectsCommand(listObjectsParams));

    const imageObjects = response.Contents;

    const imageUrlsWithMetadata = await Promise.all(
      imageObjects.map(async (object) => {
        const headObjectParams = {
          Bucket,
          Key: object.Key,
        };
  
        const headObjectResponse = await this.s3Client.send(new HeadObjectCommand(headObjectParams));
  
        // Extract custom metadata from the response headers
        const customMetadata: Record<string, string> = {};
        for (const header in headObjectResponse.Metadata) {
          if (headObjectResponse.Metadata.hasOwnProperty(header)) {
            customMetadata[header] = headObjectResponse.Metadata[header];
          }
        }
  
        return {
          src: `https://${Bucket}.s3.amazonaws.com/${object.Key}`,
          width: customMetadata.width,
          height: customMetadata.height,
        };
      })
    );


    // let imageUrls = []
    // if (imageObjects) {
    //   imageUrls = imageObjects.map((object) => {
    //     return{
    //       src: `https://${Bucket}.s3.amazonaws.com/${object.Key}`,
    //     }
    //   }
        
    //   );
    // }

    return imageUrlsWithMetadata;
  }

  async uploadFile(file: Express.Multer.File, body: any): Promise<any> {

    return new Promise(async (resolve, reject) => {
      try {
        if (!file) {
          reject(new Error('No file uploaded'));
          return;
        }

        const params = {
          Bucket: this.configService.get<string>('S3_BUCKET'),
          Key: `${Date.now().toString()}-${file.originalname}`,
          Body: file.buffer,
          Metadata: {
            'width': body.width,
            'height': body.height
          }
        };

        const upload = new Upload({
          client: this.s3Client,
          params,
          tags: [], // optional tags
          queueSize: 4, // optional concurrency configuration
          partSize: 1024 * 1024 * 5, // optional size of each part, in bytes, at least 5MB
        });

        upload.done()
          .then((data) => {
            console.log('Upload successful');
            resolve(data);
          })
          .catch((err) => {
            console.error('Upload error:', err);
            reject(err);
          });

      } catch (error) {
        reject(error);
      }
    });
  }
}
