import { headers as getHeaders } from 'next/headers.js'
import Image from 'next/image'
import { getPayload } from 'payload'
import React from 'react'

import config from '@/payload.config'
import './styles.css'

export default async function HomePage() {
  const headers = await getHeaders()
  const payloadConfig = await config
  const payload = await getPayload({ config: payloadConfig })
  
  // Fetch products from the database
  const { docs: products } = await payload.find({
    collection: 'products',
    depth: 1,
    limit: 100,
  })

  return (
    <div className="stark-container">
      <header className="stark-header">
        <div className="logo-container">
          <div className="arc-reactor-logo"></div>
          <h1>STARK INDUSTRIES</h1>
        </div>
        <nav className="stark-nav">
          <a href="#suits">Suits</a>
          <a href="#parts">Parts</a>
          <a href={payloadConfig.routes.admin} className="admin-link">Admin System</a>
        </nav>
      </header>

      <main className="stark-main">
        <section className="hero">
          <h2>THE FUTURE IS IN YOUR HANDS</h2>
          <p>Cutting-edge armor and repulsor technology available for authorized personnel.</p>
        </section>

        <section className="products-grid" id="suits">
          {products.map((product) => (
            <div key={product.id} className="product-card">
              <div className="card-image-container">
                <img
                  src={product.image || 'https://via.placeholder.com/400'}
                  alt={product.title}
                  width="400"
                  height="400"
                  className="product-image"
                />
                <div className="hologram-overlay"></div>
              </div>
              <div className="product-info">
                <span className="product-category">{product.category.toUpperCase()}</span>
                <h3>{product.title}</h3>
                <p className="product-desc">{product.description}</p>
                <div className="product-footer">
                  <span className="product-price">
                    {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(product.price)}
                  </span>
                  <button className="stark-button">ACQUIRE</button>
                </div>
              </div>
            </div>
          ))}
          {products.length === 0 && (
            <p className="no-products">Initializing Stark Database... No products found.</p>
          )}
        </section>
      </main>

      <footer className="stark-footer">
        <p>&copy; {new Date().getFullYear()} Stark Industries. Classified.</p>
      </footer>
    </div>
  )
}
