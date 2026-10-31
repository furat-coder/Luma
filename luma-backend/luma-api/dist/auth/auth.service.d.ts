import { LoginDto } from './dto/login.dto.js';
import { RegisterDto } from './dto/register.dto.js';
export declare class AuthService {
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
    verifyEmail(emailInput: string, codeInput: string): Promise<{
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
    resendVerification(emailInput: string): Promise<{
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
    logout(token: string): Promise<{
        success: boolean;
        message: string;
    }>;
}
