import { IsString, MinLength, MaxLength } from 'class-validator';

export class LoginDto {
  @IsString()
  @MinLength(3)
  @MaxLength(100)
  identifier: string;

  @IsString()
  @MinLength(8)
  @MaxLength(100)
  password: string;
}
