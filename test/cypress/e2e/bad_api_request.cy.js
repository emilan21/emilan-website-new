describe('count api testing', () => {
   let countItem;
   it('fetches Count items - POST', () => {
   	cy.request({
		method: 'POST',
		url: 'https://7voh9igajc.execute-api.us-east-1.amazonaws.com/eric_milan_dev_prod/counts/get',
		headers: {
			'Content-Type': 'application/json'
		},
		body: {
			cd: 0
		}
		}).then(
  		(response) => {
    		// response.body is automatically serialized into JSON
			expect(response.status).to.eq(200)
    			expect(response.body).to.have.property('errorMessage', "'id'") // true
    			expect(response.body).to.have.property('errorType', 'KeyError') // true
  		}
	)
   });
});
