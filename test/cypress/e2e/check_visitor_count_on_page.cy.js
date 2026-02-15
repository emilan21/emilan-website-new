describe('Check Visitor Count on Page', () => {
  it('visit exists', () => {
        cy.visit('/')
	cy.get('#visits').contains(/10|[1-9]/) 
  })
})
