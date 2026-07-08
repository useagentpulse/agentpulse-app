// Copy button
document.querySelectorAll('.copy-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const text = btn.dataset.copy
    navigator.clipboard.writeText(text).then(() => {
      btn.textContent = 'Copied!'
      btn.classList.add('copied')
      setTimeout(() => {
        btn.textContent = 'Copy'
        btn.classList.remove('copied')
      }, 2000)
    })
  })
})

// Intersection observer — fade in sections
const observer = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.style.opacity = '1'
      entry.target.style.transform = 'translateY(0)'
    }
  })
}, { threshold: 0.1 })

document.querySelectorAll('.feature-card, .state-card, .install-step, .timeline-item, .roadmap-item, .changelog-entry').forEach(el => {
  el.style.opacity = '0'
  el.style.transform = 'translateY(16px)'
  el.style.transition = 'opacity 0.5s ease, transform 0.5s ease'
  observer.observe(el)
})

// Simulate live session updates in mockup (running → permission cycling)
const statusDots = document.querySelectorAll('.popup-sessions .status-dot')
const statusLabels = document.querySelectorAll('.session-status')
