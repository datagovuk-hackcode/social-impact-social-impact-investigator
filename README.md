# Social Impact Hack

App to allow potential investors to look at both financial info and social impact info on companies. Written for [Hack for Social Impact](http://rewiredstate.org/hacks/hackforsocialimpact).

**Very** messy code, as it was for a hackathon.

Hosted online at [socialimpact.harryricards.com](http://socialimpact.harryrickards.com). [Example API endpoint](http://socialimpact.harryrickards.com/api/companies/apple).

### Data
Categories data from [20% by 2020 Women on Boards Company Directory](http://www.2020wob.com/company-directory).

Companies' financial data from:

 * [Duedil](https://www.duedil.com/). Currently using their sandbox API, which only returns data for a small number of companies (e.g., Tesco, Apple). We're using it for general company and financial data (`financial' in the API).
 * [Yahoo Finance](http://finance.yahoo.com/q?s=AAPL). Using their API for stocks information (`stocks') in the API, and generating a link to their historical stock price chart.

Companies' social impact data from:

 * [WeGreen](http://wegreen.de). Provides a score on overall CSR. We couldn't get access to their API during the hackweekend, so had to use their CSV downloads. `wegreen` in the API.
 * [20% by 2020 Women on Boards Company Directory](http://www.2020wob.com/company-directory). Used for information on the number of women in boards. At the moment, we're just scraping their site. `women_board_members` in the API.
 * [CSRHub](http://www.csrhub.com). Used for their overall CSR information, company description and ticker (e.g., [Apple](http://www.csrhub.com/CSR_and_sustainability_information/Apple-Inc/)). You have to pay for raw data access, so we're just scraping the site. `csrhub`
 * [Glassdoor](http://www.glassdoor.com/) Used for employee reviews of companies. API access seems to be invite-only, so again we're just scraping their site. `lassdoor' in the API.
 * [Vigeo](http://www.vigeo.com/csr-rating-agency/en/how-are-companies-worldwide-performing-against-csr-objectives). Used to check if a company is on their list of the top 100 companies with regards to CSR. Data obtained manually from their PDF. `vigeo' in the API.
 * [CDP S&P 500 Climate Change Report](https://www.cdp.net/CDPResults/CDP-SP500-climate-report-2013.pdf). Used for a carbon score for S&P 500 companies. Data imported manually from their PDF. Data is under `cdp' in the API.
 * [Global Reptrak 100](http://www.reputationinstitute.com/thought-leadership/global-reptrak-100) for rankings of the world's top 250 most reputable and best regarded companies. Data was manually imported from their PDFs. Data is under `most_reputable' and `best_regarded' in the API.

### Example API responses
Company info

    GET http://socialimpact.harryrickards.com/api/companies/apple

    {
       "most_reputable":{
          "rank":12,
          "score":74.65
       },
       "best_regarded":{
          "rank":9,
          "score":69.21
       },
       "wegreen":{
          "score":"3.5"
       },
       "women_board_members":{
          "total_board":8,
          "num_of_women":1,
          "percentage_of_women":"13%",
          "sector":"Technology",
          "state":"California",
          "city":"Cupertino"
       },
       "csrhub":{
          "description":"Apple, Inc. is a manufacturer and distributor of electronic products including personal computers, mobile phones, mp3 music players, and tablet computers as well as software and applications for their electronic devices. The Company, founded in 1977, also operates stores that offer Apple, Inc. products and customer service and solutions for these products. The Company is based in Cupertino, California.",
          "ticker":"AAPL",
          "isin":"US0378331005",
          "address":"1 Infinite Loop, USA, Cupertino CA, 95014",
          "website":"Apple Inc.",
          "phone_number":"1-408-9961010",
          "ratings":{
             "adjusted":{
                "overall":55,
                "community":52,
                "employees":62,
                "environment":57,
                "governance":47
             },
             "average":{
                "overall":52,
                "community":53,
                "employees":56,
                "environment":52,
                "governance":50
             }
          }
       },
       "glassdoor":{
          "rating":3.9,
          "num_reviews":2840,
          "ceo_approval":"93%",
          "recommend_to_a_friend":"81%",
          "ratings":{
             "culture_and_values":4.1,
             "work_life_balance":3.5,
             "senior_management":3.5,
             "comp_and_benefits":3.8,
             "career_opportunities":3.3
          },
          "reviews":[
             {
                "review":"Yes, I would recommend this company to a friend  I'm optimistic about the outlook for this company",
                "pro":"Really enjoyed the atmosphere the company created for working at the store",
                "con":"Tend not to promote from withen"
             }
          ]
       },
       "vigeo":{
          "on_list":false
       },
       "cdp":{
    
       },
       "social_impact_score":8.3,
       "financial":{
          "id":"01591116",
          "name":"APPLE (UK) LIMITED",
          "description":"uProvides services to group companies including sales support, marketing and technical support.",
          "status":"L",
          "incorporationDate":"1981-10-14",
          "latestAnnualReturnDate":"2012-08-26",
          "latestAccountsDate":"2011-09-24",
          "companyType":"2",
          "accountsType":"1",
          "sicCode":"7260",
          "sicDescription":"OTHER COMPUTER RELATED ACTIVITIES",
          "accountsCash":344000,
          "accountsCurrency":"GBP",
          "accountsDividendsPayable":20565000,
          "accountsNoOfEmployees":319,
          "directorsTotal":26,
          "directorshipsTotal":32,
          "directorshipsOpen":3,
          "directorshipsOpenSecretary":1,
          "directorshipsOpenDirector":2,
          "directorshipsRetired":29,
          "directorshipsRetiredSecretary":8,
          "directorshipsRetiredDirector":21,
          "accountsFilingDate":"2012-06-14",
          "regAddressPostcode":"EC4V 6JA",
          "regAreaCode":"EC4V",
          "regWeb":"APPLE.COM/UK",
          "tradingAddress1":"2 Furze Ground Way",
          "tradingAddress2":"Stockley Park",
          "tradingAddress3":"Uxbridge",
          "tradingAddress4":"Middlesex",
          "tradingAddressPostcode":"UB11 1BB",
          "tradingPhone":"82181000",
          "tradingPhoneStd":"020"
       },
       "stocks":{
          "symbol":"AAPL",
          "average_daily_volume":12745300.0,
          "bid":524.8,
          "dividend_per_share":12.2,
          "earnings_per_share":40.233,
          "low_52_weeks":385.1,
          "high_52_weeks":575.14,
          "close":525.25,
          "dividend_yield":2.3,
          "stock_exchange":"NasdaqNM"
       },
       "financial_score":14.0
    }

    http://socialimpact.harryrickards.com/api/companies/apple

Categories list

    GET http://socialimpact.harryrickards.com/api/categories

    [
     "Industrials",
     "Basic Materials",
     "Healthcare",
     "Consumer Cyclical",
     "Technology",
     "Financial Services",
     "Energy",
     "Utilities",
     "Real Estate",
     "Consumer Defensive",
     "Communication Services",
     "Services"
    ]


Companies in a category

    GET http://socialimpact.harryrickards.com/api/categories/Healthcare

    [
      {
        "name":"Abbott Laboratories",
        "url":"/api/companies/Abbott%20Laboratories"
      },
      ...
      {
       "name":"Zimmer Holdings, Inc.",
       "url":"/api/companies/Zimmer%20Holdings%20Inc"
      }
    ]
