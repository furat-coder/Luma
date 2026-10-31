import { AuthService } from './auth.service.js';
import { LoginDto } from './dto/login.dto.js';
import { RegisterDto } from './dto/register.dto.js';
import { VerifyEmailDto } from './dto/verify-email.dto.js';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    register(registerDto: RegisterDto): Promise<{
        success: boolean;
        message: string;
        account: {
            id: number;
            email: string;
            username: string;
            displayName: string | null;
            profileImage: string | null;
            isVerified: boolean;
            isActive: boolean;
            createdAt: string;
        };
        verification: {
            code: string;
            expiresAt: string;
        };
    }>;
    verifyEmail(verifyEmailDto: VerifyEmailDto): Promise<{
        success: boolean;
        message: string;
        session: {
            token: string;
            expiresAt: string;
        };
        account: {
            id: number;
            email: string;
            username: string;
            displayName: string | null;
            profileImage: string | null;
            isVerified: boolean;
            isActive: boolean;
        };
    }>;
    resendVerification(email: string): Promise<{
        success: boolean;
        message: string;
        verification: {
            code: string;
            expiresAt: string;
        };
    }>;
    login(loginDto: LoginDto): Promise<{
        success: boolean;
        message: string;
        session: {
            token: string;
            expiresAt: string;
        };
        account: {
            id: number;
            email: string;
            username: string;
            displayName: string | null;
            profileImage: string | null;
            isVerified: boolean;
            isActive: true;
        };
    }>;
    me(request: any): {
        success: boolean;
        account: {
            id: any;
            email: any;
            username: any;
            displayName: any;
            profileImage: any;
            isVerified: any;
            isActive: any;
        };
    };
    logout(authorization: string): Promise<{
        success: boolean;
        message: string;
    }>;
}
