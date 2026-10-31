import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';

import { db } from '../prisma/db.js';

import { UpdateProfileDto } from './dto/update-profile.dto.js';

@Injectable()
export class UsersService {
  async updateProfile(accountId: number, updateProfileDto: UpdateProfileDto) {
    const account = await db.orm.public.Account.first({
      id: accountId,
    });

    if (!account) {
      throw new NotFoundException('Account not found');
    }

    if (!account.isActive) {
      throw new UnauthorizedException('This account is inactive');
    }

    const updates: Record<string, unknown> = {};

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
}
