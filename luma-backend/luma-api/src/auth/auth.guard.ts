import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

import { db } from '../prisma/db.js';

@Injectable()
export class AuthGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();

    const authorization = request.headers.authorization;

    if (!authorization) {
      throw new UnauthorizedException('Missing authorization token');
    }

    const [scheme, token] = authorization.split(' ');

    if (scheme !== 'Bearer' || !token) {
      throw new UnauthorizedException('Invalid authorization format');
    }

    const session = await db.orm.public.Session.first({
      token,
    });

    if (!session) {
      throw new UnauthorizedException('Invalid or expired session');
    }

    const expiresAt = new Date(session.expiresAt);

    if (expiresAt.getTime() <= Date.now()) {
      throw new UnauthorizedException('Session has expired');
    }

    const account = await db.orm.public.Account.first({
      id: session.accountId,
    });

    if (!account || !account.isActive) {
      throw new UnauthorizedException('Account is unavailable');
    }

    request.account = account;
    request.session = session;

    return true;
  }
}
