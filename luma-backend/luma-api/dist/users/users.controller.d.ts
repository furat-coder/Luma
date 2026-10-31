import { UpdateProfileDto } from './dto/update-profile.dto.js';
import { UsersService } from './users.service.js';
export declare class UsersController {
    private readonly usersService;
    constructor(usersService: UsersService);
    updateProfile(request: any, updateProfileDto: UpdateProfileDto): Promise<{
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
