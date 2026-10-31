var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
import { ConflictException, Injectable, NotFoundException, UnauthorizedException, } from '@nestjs/common';
import { db } from '../prisma/db.js';
let UsersService = class UsersService {
    async updateProfile(accountId, updateProfileDto) {
        const account = await db.orm.public.Account.first({
            id: accountId,
        });
        if (!account) {
            throw new NotFoundException('Account not found');
        }
        if (!account.isActive) {
            throw new UnauthorizedException('This account is inactive');
        }
        const updates = {};
        if (updateProfileDto.displayName !== undefined) {
            const displayName = updateProfileDto.displayName.trim();
            if (displayName.length === 0) {
                throw new ConflictException('Display name cannot be empty');
            }
            updates.displayName = displayName;
        }
        if (updateProfileDto.username !== undefined) {
            const username = updateProfileDto.username.trim().toLowerCase();
            if (username.length === 0) {
                throw new ConflictException('Username cannot be empty');
            }
            const existingUsername = await db.orm.public.Account.first({
                username,
            });
            if (existingUsername && existingUsername.id !== account.id) {
                throw new ConflictException('Username is already taken');
            }
            updates.username = username;
        }
        if (Object.keys(updates).length > 0) {
            await db.orm.public.Account.where({
                id: account.id,
            }).update(updates);
        }
        const updatedAccount = await db.orm.public.Account.first({
            id: account.id,
        });
        if (!updatedAccount) {
            throw new NotFoundException('Updated account could not be loaded');
        }
        return {
            success: true,
            message: 'Profile updated successfully',
            account: {
                id: updatedAccount.id,
                email: updatedAccount.email,
                username: updatedAccount.username,
                displayName: updatedAccount.displayName,
                profileImage: updatedAccount.profileImage,
                isVerified: updatedAccount.isVerified,
                isActive: updatedAccount.isActive,
            },
        };
    }
};
UsersService = __decorate([
    Injectable()
], UsersService);
export { UsersService };
//# sourceMappingURL=users.service.js.map