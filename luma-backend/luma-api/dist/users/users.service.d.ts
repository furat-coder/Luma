import { UpdateProfileDto } from './dto/update-profile.dto.js';
export declare class UsersService {
    updateProfile(accountId: number, updateProfileDto: UpdateProfileDto): Promise<{
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
        };
    }>;
}
