import { Controller, Get, Req } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) { }

  @Get("*")
  getHello(@Req() request: Request): object {
    return {
      message: `${this.appService.getHello()}-${request.url}`,
      status: 200
    };
  }
}
