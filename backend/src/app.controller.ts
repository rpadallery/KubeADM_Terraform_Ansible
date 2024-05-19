import { Body, Controller, Get, Post, Req, Res, UploadedFile, UseInterceptors } from '@nestjs/common';
import { AppService } from './app.service';
import { FileInterceptor } from '@nestjs/platform-express';
import { Request, Response } from 'express';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('/gallery')
  async getGallery(@Res() res: Response) {
    try {
      const imageUrls = await this.appService.getGallery();
      res.status(200).json(imageUrls);
    } catch (error) {
      console.error(error);
      res.status(500).json({
        message: 'An error occurred while fetching image URLs.',
        error: error.message,
      });
    }
  }

  @Post('upload')
  @UseInterceptors(FileInterceptor('image'))
  async uploadFile(@UploadedFile() file: Express.Multer.File, @Body() body: any) {
    try {
      const data = await this.appService.uploadFile(file, body);
      return {
        message: 'Success',
        data,
      };
    } catch (error) {
      // Handle error
    }
  }
}
