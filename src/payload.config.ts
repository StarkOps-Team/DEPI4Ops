import { mongooseAdapter } from '@payloadcms/db-mongodb'
import { lexicalEditor } from '@payloadcms/richtext-lexical'
import path from 'path'
import { buildConfig } from 'payload'
import { fileURLToPath } from 'url'
import sharp from 'sharp'

import { Users } from './collections/Users'
import { Media } from './collections/Media'
import { Products } from './collections/Products'

const filename = fileURLToPath(import.meta.url)
const dirname = path.dirname(filename)

export default buildConfig({
  admin: {
    user: Users.slug,
    importMap: {
      baseDir: path.resolve(dirname),
    },
  },
  collections: [Users, Media, Products],
  onInit: async (payload) => {
    // Check if we need to seed the database
    const { totalDocs } = await payload.find({
      collection: 'products',
      limit: 1,
    })

    if (totalDocs === 0) {
      payload.logger.info('No products found. Seeding database with Iron Man products...')
      const seedProducts: Array<{
        title: string
        description: string
        price: number
        category: 'suit' | 'part' | 'accessory'
        image: string
      }> = [
        {
          title: 'Mark XLVII Suit',
          description: 'The pinnacle of Stark tech. Features advanced nanotechnology, flight capabilities, and full combat systems.',
          price: 1500000000,
          category: 'suit',
          image: '/suit.png',
        },
        {
          title: 'Repulsor Arm (Left)',
          description: 'Replacement left arm unit with integrated repulsor blast technology and stabilization thrusters.',
          price: 5000000,
          category: 'part',
          image: '/arm.png',
        },
        {
          title: 'Arc Reactor Mark I',
          description: 'Proof that Tony Stark has a heart. Provides 3 gigajoules per second of energy.',
          price: 30000000,
          category: 'part',
          image: '/reactor.png',
        },
        {
          title: 'Iron Man Helmet (Mark III)',
          description: 'Classic gold and hot rod red helmet. Includes HUD and F.R.I.D.A.Y. integration.',
          price: 1500000,
          category: 'accessory',
          image: '/helmet.png',
        },
      ]

      for (const product of seedProducts) {
        await payload.create({
          collection: 'products',
          data: product,
        })
      }
      payload.logger.info('Database seeding completed successfully.')
    }
  },
  editor: lexicalEditor(),
  secret: process.env.PAYLOAD_SECRET || '',
  typescript: {
    outputFile: path.resolve(dirname, 'payload-types.ts'),
  },
  db: mongooseAdapter({
    url: process.env.DATABASE_URL || '',
  }),
  sharp,
  plugins: [],
})
