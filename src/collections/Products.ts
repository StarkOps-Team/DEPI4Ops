import type { CollectionConfig } from 'payload'

export const Products: CollectionConfig = {
  slug: 'products',
  admin: {
    useAsTitle: 'title',
  },
  access: {
    read: () => true, // Publicly readable
  },
  fields: [
    {
      name: 'title',
      type: 'text',
      required: true,
    },
    {
      name: 'description',
      type: 'textarea',
      required: true,
    },
    {
      name: 'price',
      type: 'number',
      required: true,
    },
    {
      name: 'category',
      type: 'select',
      options: [
        { label: 'Suit', value: 'suit' },
        { label: 'Part', value: 'part' },
        { label: 'Accessory', value: 'accessory' },
      ],
      required: true,
    },
    {
      name: 'image',
      type: 'text',
      required: true,
      admin: {
        description: 'URL to the product image',
      },
    },
  ],
}
