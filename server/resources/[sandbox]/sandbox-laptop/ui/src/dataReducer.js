export const initialState = {
	data:
		process.env.NODE_ENV != 'production'
			? {
					externalJobs: ['police', 'ems'],
					player: null,
					playerJobPerms: null,
					JobData: null,
					externalJobs: [],
					onDuty: 'realestate',
					myGroup: {
						ID: 1,
						Name: 'Team Name',
						Members: Array(
							{
								Leader: true,
								SID: 1,
								First: 'Testy',
								Last: 'McTest',
							},
							{
								SID: 2,
								First: 'Shit',
								Last: 'Dick',
							},
						),
						State: 0,
					},
					myGroup: null,
					// boostingQueue: {
					// 	joined: 1673559272
					// },
					player: {
						Source: 1,
						_id: '6088b90c93a7b379e0c83ef2',
						ID: '6088b90c93a7b379e0c83ef2',
						User: '606c22a749c1c980e8289b35',
						SID: 1,
						Phone: '121-195-9016',
						Gender: 0,
						Callsign: 404,
						Jobs: [
							{
								Workplace: {
									Id: 'dyn8',
									Name: 'Dynasty 8',
								},
								Name: 'Real Estate',
								Grade: {
									Id: 'owner',
									Name: 'Owner',
								},
								Id: 'realestate',
							},
						],
						Origin: 'United States',
						First: 'Testy',
						Last: 'McTest',
						DOB: '1991-01-01T07:59:59.000Z',
						LastPlayed: 1619819253000,
						Keys: {
							'60af7d605716b35d64c6c4a1': true,
						},
						Alias: {
							twitter: {
								avatar: '',
								name: 'sdfsdf',
							},
							irc: 'anon6088b',
							redline: 'Test',
						},
						Crypto: {
							ZRM: 100,
							VRM: 10000,
							MEME: 100,
						},
						Animations: {
							expression: 'default',
							walk: 'default',
							emoteBinds: [],
						},
						LaptopApps: {
							home: [
								'settings',
								'files',
								'internet',
								'bizwiz',
								'teams',
								'lsunderground',
							],
							installed: [
								'settings',
								'files',
								'bizwiz',
								'internet',
								'teams',
								'lsunderground',
							],
						},
						Apps: {
							home: [
								'redline',
								'twitter',
								'leoassist',
								'bank',
								'email',
								'irc',
								'adverts',
								'contacts',
								'phone',
								'store',
								'settings',
								'messages',
								'labor',
								'comanager',
								'crypto',
								'dyn8',
								'homemanage',
								'govt',
								'garage',
								'pingem',
								'calculator',
								'documents',
								'lsunderground',
							],
							dock: [
								'contacts',
								'phone',
								'messages',
								'lsunderground',
							],
							installed: [
								'redline',
								'twitter',
								'leoassist',
								'bank',
								'calculator',
								'email',
								'irc',
								'adverts',
								'contacts',
								'phone',
								'store',
								'settings',
								'messages',
								'labor',
								'comanager',
								'crypto',
								'dyn8',
								'homemanage',
								'govt',
								'garage',
								'pingem',
								'documents',
								'lsunderground',
							],
						},
						Armor: 100,
						HP: 200,
						LaptopPermissions: {
							redline: {
								create: true,
							},
							supplymate: {
								buyer: true,
								contractor: true,
								admin: true,
							},
							lsunderground: {
								admin: true,
							},
						},
						PhoneSettings: {
							texttone: 'text1.ogg',
							ringtone: 'ringtone1.ogg',
							wallpaper: 'wallpaper',
							colors: {
								accent: '#1a7cc1',
							},
							notifications: true,
							zoom: 105,
							volume: 100,
							appNotifications: [],
						},
						LaptopSettings: {
							texttone: 'text1.ogg',
							ringtone: 'ringtone1.ogg',
							wallpaper: 'wallpaper9',
							colors: {
								accent: '#D50000',
							},
							notifications: true,
							zoom: 105,
							volume: 100,
							appNotifications: [],
						},
						Status: {
							PLAYER_HUNGER: 71,
							PLAYER_THIRST: 72,
						},
						States: [
							'PHONE_VPN',
							'RACE_DONGLE',
							'ACCESS_LSUNDERGROUND',
							'ACCESS_BOOSTING',
						],
						Reputations: {
							Racing: 5000,
							Boosting: 25000,
						},
					},
					playerTeams: [
						{
							_id: 1,
							name: 'Meal Team 6',
							members: [1, 2, 3],
						},
					],
					playerJobPerms: {
						JOB_FIRE: true,
						JOB_HIRE: true,
						JOB_FLEET_ACCESS: true,
						JOB_MANAGE_EMPLOYEES: true,
						JOB_MANAGEMENT: true,
						JOB_SUPERVISOR: true,
						JOB_PAY_EMPLOYEES: true,
						JOB_PAY_CUSTOMERS: true,
						JOB_SELL: true,
					},
					JobData: {
						Id: 'police',
						Name: 'Police',
						Owner: '6088b90c93a7b379e0c83ef2',
						Upgrades: {
							COMPANY_FLEET: true,
						},
						Workplaces: [
							{
								Name: 'Los Santos Police Department',
								Id: 'lspd',
								Grades: [
									{
										Name: 'Cadet',
										Id: 'cadet',
										Level: 1,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
										},
									},
									{
										Name: 'Probationary Officer',
										Id: 'pofficer',
										Level: 2,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
										},
									},
									{
										Name: 'Officer I',
										Id: 'officer1',
										Level: 3,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
										},
									},
									{
										Name: 'Officer II',
										Id: 'officer2',
										Level: 4,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_1: true,
											police_cars_0: true,
											police_cars_2: true,
										},
									},
									{
										Name: 'Sergeant',
										Id: 'sergeant',
										Level: 5,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_investigation: true,
											lspd_supervisor: true,
										},
									},
									{
										Name: 'Lieutenant',
										Id: 'lieutenant',
										Level: 6,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											lspd_supervisor: true,
										},
									},
									{
										Name: 'Captain',
										Id: 'captain',
										Level: 7,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_investigation: true,
											police_cars_4: true,
											lspd_supervisor: true,
											lspd_hc: true,
										},
									},
									{
										Name: 'Deputy Chief',
										Id: 'dchief',
										Level: 8,
										Permissions: {
											generic_doors: true,
											police_doors: true,
											ems_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_supervisor: true,
											police_investigation: true,
											lspd_hc: true,
											leo_hc: true,
										},
									},
									{
										Name: 'Chief',
										Id: 'chief',
										Level: 9,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											lspd_supervisor: true,
											lspd_hc: true,
											leo_hc: true,
											JOB_MANAGEMENT: true,
										},
									},
								],
							},
							{
								Name: "Blaine County Sheriff's Office",
								Id: 'bcso',
								Grades: [
									{
										Name: 'Cadet',
										Id: 'cadet',
										Level: 1,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
										},
									},
									{
										Name: 'Probationary Deputy',
										Id: 'pdeputy',
										Level: 2,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
										},
									},
									{
										Name: 'Deputy',
										Id: 'deputy',
										Level: 3,
										Permissions: {
											police_doors: true,
											generic_doors: true,
											ems_doors: true,
											police_cars_0: true,
											police_cars_1: true,
										},
									},
									{
										Name: 'Senior Deputy',
										Id: 'sdeputy',
										Level: 4,
										Permissions: {
											police_cars_1: true,
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_2: true,
										},
									},
									{
										Name: 'Sergeant',
										Id: 'sergeant',
										Level: 5,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_investigation: true,
											bcso_supervisor: true,
										},
									},
									{
										Name: 'Lieutenant',
										Id: 'lieutenant',
										Level: 6,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											bcso_supervisor: true,
										},
									},
									{
										Name: 'Captain',
										Id: 'captain',
										Level: 7,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											bcso_supervisor: true,
											bcso_hc: true,
										},
									},
									{
										Name: 'Assistant Sheriff',
										Id: 'asheriff',
										Level: 8,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											bcso_supervisor: true,
											bcso_hc: true,
											leo_hc: true,
										},
									},
									{
										Name: 'Sheriff',
										Id: 'sheriff',
										Level: 9,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											bcso_supervisor: true,
											bcso_hc: true,
											leo_hc: true,
										},
									},
								],
							},
							{
								Name: "Las Santos County Sheriff's Department",
								Id: 'lssd',
								Grades: [
									{
										Name: 'Cadet',
										Id: 'cadet',
										Level: 1,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
										},
									},
									{
										Name: 'Probationary Deputy',
										Id: 'pdeputy',
										Level: 2,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
										},
									},
									{
										Name: 'Senior Deputy',
										Id: 'sdeputy',
										Level: 3,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
										},
									},
									{
										Name: 'Deputy',
										Id: 'deputy',
										Level: 4,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
										},
									},
									{
										Name: 'Sergeant',
										Id: 'sergeant',
										Level: 5,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_investigation: true,
											lssd_supervisor: true,
										},
									},
									{
										Name: 'Lieutenant',
										Id: 'lieutenant',
										Level: 6,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											lssd_supervisor: true,
										},
									},
									{
										Name: 'Captain',
										Id: 'captain',
										Level: 7,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_3: true,
											police_cars_2: true,
											police_cars_4: true,
											police_investigation: true,
											lssd_supervisor: true,
											lssd_hc: true,
										},
									},
									{
										Name: 'Assistant Sheriff',
										Id: 'asheriff',
										Level: 8,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											lssd_supervisor: true,
											lssd_hc: true,
											leo_hc: true,
										},
									},
									{
										Name: 'Sheriff',
										Id: 'sheriff',
										Level: 9,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											lssd_supervisor: true,
											lssd_hc: true,
											leo_hc: true,
										},
									},
								],
							},
							{
								Name: 'San Andreas State Police',
								Id: 'sasp',
								Grades: [
									{
										Name: 'State Trooper',
										Id: 'trooper',
										Level: 4,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
										},
									},
									{
										Name: 'Sergeant',
										Id: 'sergeant',
										Level: 5,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_investigation: true,
											sasp_supervisor: true,
										},
									},
									{
										Name: 'Lieutenant',
										Id: 'lieutenant',
										Level: 6,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											police_cars_0: true,
											police_cars_2: true,
											generic_doors: true,
											police_cars_1: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											sasp_supervisor: true,
										},
									},
									{
										Name: 'Major',
										Id: 'major',
										Level: 7,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											sasp_supervisor: true,
											sasp_hc: true,
										},
									},
									{
										Name: 'Deputy Superintendent',
										Id: 'dsuperint',
										Level: 8,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											sasp_supervisor: true,
											sasp_hc: true,
											leo_hc: true,
										},
									},
									{
										Name: 'Superintendent',
										Id: 'superint',
										Level: 9,
										Permissions: {
											police_doors: true,
											ems_doors: true,
											generic_doors: true,
											police_cars_0: true,
											police_cars_1: true,
											police_cars_2: true,
											police_cars_3: true,
											police_cars_4: true,
											police_investigation: true,
											sasp_supervisor: true,
											sasp_hc: true,
										},
									},
								],
							},
						],
					},
					jobPermissions: {
						JOB_FIRE: 'Fire Employees',
						JOB_HIRE: 'Hire Employees',
						JOB_FLEET_ACCESS: 'Access Company Fleet',
						JOB_MANAGE_EMPLOYEES: 'Manage Employees',
						JOB_MANAGEMENT: 'Company Management',
						JOB_PAY_EMPLOYEES: 'Pay Internal',
						JOB_PAY_CUSTOMERS: 'Pay External',
					},
					JobPermissions: {
						realestate: {
							JOB_SELL: true,
						},
					},
					items: {
						rubber: {
							label: 'Rubber',
							price: 100,
						},
						plastic: {
							label: 'Plastic',
							price: 100,
						},
						electronic_parts: {
							label: 'Electronic Parts',
							price: 100,
						},
						copperwire: {
							label: 'Copper Wire',
							price: 100,
						},
						glue: {
							label: 'Glue',
							price: 100,
						},
						heavy_glue: {
							label: 'Heavy Duty Glue',
							price: 100,
						},
						goldbar: {
							label: 'Gold bar',
							price: 100,
						},
						silverbar: {
							label: 'Silver Bar',
							price: 100,
						},
						ironbar: {
							label: 'Iron Bar',
							price: 100,
						},
					},
					activeOrders: [
						{
							_id: 1,
							tier: 2,
							date: 1655253565,
							items: [
								{
									item: 'rubber',
									amount: 10000,
								},
							],
							payment: {
								coin: 'PLEB',
								amount: 240,
							},
							creator: 1,
						},
						{
							_id: 4,
							tier: 2,
							date: 1655256862,
							items: [
								{
									item: 'rubber',
									amount: 10000,
								},
							],
							payment: {
								coin: 'PLEB',
								amount: 240,
							},
							creator: 1,
						},
					],
					pastOrders: [
						{
							_id: 2,
							tier: 2,
							date: 1655253553,
							items: [
								{
									item: 'rubber',
									amount: 10000,
								},
							],
							team: {
								id: 3,
								name: 'KEKW',
							},
							payment: {
								coin: 'PLEB',
								amount: 240,
							},
						},
						{
							_id: 3,
							tier: 2,
							date: 1655256857,
							items: [
								{
									item: 'rubber',
									amount: 10000,
								},
							],
							team: {
								id: 2,
								name: 'sandbox',
							},
							payment: {
								coin: 'PLEB',
								amount: 240,
							},
						},
					],
					activeTeams: [
						{
							_id: 1,
							name: 'Meal Team 6',
							owner: 8,
							members: [8, 9, 10],
						},
					],
					disabledBoostingContracts: [],
					businessPages: [
						{
							id: 'Dashboard',
							icon: ['fas', 'file-lines'],
							label: 'Dashboard',
						},
						{
							id: 'Create/Document',
							icon: ['fas', 'file-lines'],
							label: 'New Document',
						},
						{
							id: 'Search/Document',
							icon: ['fas', 'file-lines'],
							label: 'Documents',
						},
						{
							id: 'Search/Receipt',
							icon: ['fas', 'file-lines'],
							label: 'Receipts',
						},
						{
							id: 'Search/ReceiptCount',
							icon: ['fas', 'file-lines'],
							label: 'Receipts Count',
						},
						{
							id: 'View/Document',
							icon: ['fas', 'file-lines'],
							label: 'Test',
						},
						{
							id: 'Casino/BigWin',
							icon: ['fas', 'file-lines'],
							label: 'Dyn 8',
							permission: 'TABLET_VIEW_DOCUMENT',
						},
						{
							id: 'Dynasty/Properties',
							icon: ['fas', 'house'],
							label: 'Properties',
							permission: 'JOB_SELL',
						},
						{
							id: 'Create/Notice',
							hidden: true,
						},
						{
							id: 'Search/Receipt',
							hidden: true,
						},
						{
							id: 'Create/Receipt',
							hidden: true,
						},
						{
							id: 'Tweet',
							icon: ['fas', 'face-grin-beam'],
							label: 'Business Spammer',
							//permission: 'TABLET_TWEET',
						},
						{
							id: 'TweetSettings',
							icon: ['fas', 'face-grin-beam'],
							label: 'Spammer Profile',
							//permission: 'TABLET_TWEET',
						},
						{
							id: 'FleetManagement',
							icon: ['fas', 'car'],
							label: 'Fleet Management',
							//permission: 'TABLET_TWEET',
						},
					],
					businessNotices: [
						{
							time: 1629380840 * 1000,
							title: 'Test',
							description: 'Test Description <b>John</b>',
						},
					],
					businessLogo: 'https://i.imgur.com/EU7HQji.png',
			  }
			: {
					disabledBoostingContracts: [],
			  },
};
export default (state = initialState, action) => {
	switch (action.type) {
		case 'SET_DATA':
			return {
				...state,
				data: {
					...state.data,
					[action.payload.type]: action.payload.data,
				},
			};
		case 'RESET_DATA':
			return initialState;
		case 'ADD_DATA':
			return {
				...state,
				data: {
					...state.data,
					[action.payload.type]:
						state.data[action.payload.type] != null
							? Object.prototype.toString.call(
									state.data[action.payload.type],
							  ) == '[object Array]'
								? action.payload.first
									? [
											action.payload.data,
											...state.data[action.payload.type],
									  ]
									: [
											...state.data[action.payload.type],
											action.payload.data,
									  ]
								: action.payload.key
								? {
										...state.data[action.payload.type],
										[action.payload.key]:
											action.payload.data,
								  }
								: {
										...state.data[action.payload.type],
										...action.payload.data,
								  }
							: [action.payload.data],
				},
			};
		case 'UPDATE_DATA':
			return {
				...state,
				data: {
					...state.data,
					[action.payload.type]:
						Object.prototype.toString.call(
							state.data[action.payload.type],
						) == '[object Array]'
							? state.data[action.payload.type].map((data) =>
									data._id == action.payload.id
										? { ...action.payload.data }
										: data,
							  )
							: (state.data[action.payload.type] = action.payload
									.key
									? {
											...state.data[action.payload.type],
											[action.payload.id]: {
												...state.data[
													action.payload.type
												][action.payload.id],
												[action.payload.key]:
													action.payload.data,
											},
									  }
									: {
											...state.data[action.payload.type],
											[action.payload.id]:
												action.payload.data,
									  }),
				},
			};
		case 'REMOVE_DATA':
			return {
				...state,
				data: {
					...state.data,
					[action.payload.type]:
						Object.prototype.toString.call(
							state.data[action.payload.type],
						) == '[object Array]'
							? state.data[action.payload.type].filter((data) => {
									return Object.prototype.toString.call(
										data,
									) == '[object Object]'
										? action.payload.key
											? data[action.payload.key] !=
											  action.payload.id
											: data._id != action.payload.id
										: data != action.payload.id;
							  })
							: (state.data[action.payload.type] = Object.keys(
									state.data[action.payload.type],
							  ).reduce((result, key) => {
									if (key != action.payload.id) {
										result[key] =
											state.data[action.payload.type][
												key
											];
									}
									return result;
							  }, {})),
				},
			};
		default:
			return state;
	}
};
