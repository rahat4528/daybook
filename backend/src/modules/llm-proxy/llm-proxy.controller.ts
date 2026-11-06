import { Controller, Post, Get, Body, Query, HttpCode, HttpStatus, BadRequestException } from '@nestjs/common';
import { LlmProxyService, GeneratePromptDto } from './llm-proxy.service';

@Controller('llm')
export class LlmProxyController {
  constructor(private readonly llmProxyService: LlmProxyService) {}

  @Post('generate')
  @HttpCode(HttpStatus.OK)
  async generate(@Body() body: GeneratePromptDto) {
    if (!body?.userId || !body?.userPrompt) {
      throw new BadRequestException('userId and userPrompt are required');
    }
    try {
      return await this.llmProxyService.generateCompletion(body);
    } catch (err: any) {
      throw new BadRequestException(err.message || 'LLM generation failed');
    }
  }

  @Get('rate-limit')
  @HttpCode(HttpStatus.OK)
  checkRateLimit(@Query('userId') userId: string) {
    if (!userId) throw new BadRequestException('userId query parameter is required');
    return this.llmProxyService.checkRateLimit(userId);
  }
}
