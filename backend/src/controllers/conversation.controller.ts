import { Request, Response } from 'express';
import Message from '../models/message.model';
import User from '../models/user.model';
import type { PipelineStage } from 'mongoose';

// Lista conversas (lista de contatos) ordenadas pela última mensagem
export const getConversations = async (req: Request, res: Response) => {
  try {
    // @ts-ignore
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ message: 'Não autenticado' });

    const pipeline: PipelineStage[] = [
      { $match: { $or: [{ from: userId }, { to: userId }] } },
      { $sort: { timestamp: -1 } },
      {
        $group: {
          _id: {
            $toObjectId: {
              $cond: [{ $eq: ['$from', userId] }, '$to', '$from']
            }
          },
          lastMessage: { $first: '$content' },
          lastMessageAt: { $first: '$timestamp' },
          lastMessageFrom: { $first: '$from' },
          lastMessageType: { $first: '$type' }
        } as any
      },
      {
        $lookup: {
          from: 'users',
            localField: '_id',
          foreignField: '_id',
          as: 'user'
        }
      },
      { $unwind: '$user' },
      {
        $project: {
          contactId: { $toString: '$_id' },
          name: '$user.name',
          photoURL: '$user.photoURL',
          lastMessage: 1,
          lastMessageAt: 1,
          lastMessageFrom: 1,
          lastMessageType: 1
        }
      },
      { $sort: { lastMessageAt: -1 } }
    ];

    const results = await Message.aggregate(pipeline);

    if (results.length === 0) {
      // Fallback: listar usuários (sem mensagens ainda)
      const users = await User.find({ _id: { $ne: userId } })
        .select('name photoURL')
        .lean();
      return res.json(
        users.map(u => ({
          contactId: u._id.toString(),
          name: u.name,
          photoURL: u.photoURL,
          lastMessage: '',
          lastMessageAt: null,
          lastMessageFrom: null,
          lastMessageType: null
        }))
      );
    }

    res.json(results);
  } catch (err) {
    res.status(500).json({ message: 'Erro ao listar conversas', error: err });
  }
};
