export const initialState = {
	data: {
		charges: [],
		warrants: Array(),
		notices: Array(),
		govWorkers: Array(),
		// govWorkers: [
		// 	{
		// 		First: 'Bob',
		// 		Last: 'Anderson',
		// 		Job: 'Government',
		// 		Workplace: 'DOJ',
		// 		Grade: 'Judge',
		// 		Phone: '111-111-111',
		// 		SID: 1,
		// 	},
		// ],
		homeLastFetch: 0,
		// notices: [
		// 	{
		// 		time: 1629380840 * 1000,
		// 		title: 'Test',
		// 		description: 'Test Description <b>John</b>',
		// 	},
		// 	{
		// 		time: 1629380840 * 1000,
		// 		title: 'Test',
		// 		description: 'Test Description <b>John</b>',
		// 	},
		// 	{
		// 		time: 1629380840 * 1000,
		// 		title: 'Test',
		// 		description: 'Test Description <b>John</b>',
		// 	},
		// 	{
		// 		time: 1629380840 * 1000,
		// 		title: 'Test',
		// 		description: 'Test Description <b>John</b>',
		// 	},
		// 	{
		// 		time: 1629380840 * 1000,
		// 		title: 'Test',
		// 		description: 'Test Description <b>John</b>',
		// 	},
		// 	{
		// 		time: 1629380840 * 1000,
		// 		title: 'Test',
		// 		description: 'Test Description <b>John</b>',
		// 	},
		// 	{
		// 		time: 1629380840 * 1000,
		// 		title: 'Test',
		// 		description: 'Test Description <b>John</b>',
		// 	},
		// 	{
		// 		time: 1629380840 * 1000,
		// 		title: 'Test',
		// 		description: 'Test Description <b>Johnface</b>',
		// 	},
		// ],
		permissions: {
			MDT_TEST_PERMISSION: {
				name: 'Test Permission',
				restrict: {
					job: 'police',
					workplace: false,
				},
			},
		},
		qualifications: [],
		governmentJobs: ['government', 'police', 'ems'],
		governmentJobsData: {
			police: {
				Id: 'police',
				Name: 'Police',
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
				],
			},
			government: JSON.parse(`{
				"Workplaces": [
				  {
					"Grades": [
					  {
						"Name": "County Clerk",
						"Level": 0,
						"Permissions": [],
						"Id": "countyclerk"
					  },
					  {
						"Name": "Judge",
						"Level": 90,
						"Permissions": [],
						"Id": "judge"
					  },
					  {
						"Name": "Justice",
						"Level": 95,
						"Permissions": [],
						"Id": "justice"
					  }
					],
					"Name": "San Andreas Department of Justice",
					"Id": "doj"
				  },
				  {
					"Grades": [
					  {
						"Name": "Prosecutor",
						"Level": 10,
						"Permissions": [],
						"Id": "prosecutor"
					  },
					  {
						"Name": "Assistant District Attorney",
						"Level": 75,
						"Permissions": [],
						"Id": "ada"
					  },
					  {
						"Name": "District Attorney",
						"Level": 80,
						"Permissions": [],
						"Id": "da"
					  }
					],
					"Name": "District Attorney's Office",
					"Id": "dattorney"
				  },
				  {
					"Grades": [
					  {
						"Name": "Deputy Mayor",
						"Level": 80,
						"Permissions": [],
						"Id": "dmayor"
					  },
					  {
						"Name": "Mayor",
						"Level": 90,
						"Permissions": [],
						"Id": "mayor"
					  }
					],
					"Name": "Mayor's Office",
					"Id": "mayoroffice"
				  }
				],
				"LastUpdated": 1628369498,
				"Type": "Government",
				"Name": "Government",
				"Id": "government"
			}`),
		},
		charges: [
			{
				id: 1,
				title: 'Attempted Murder',
				description: 'This is something that should describe what the charge is',
				type: 1,
				fine: 1000,
				jail: 25,
				points: 1,
			},
			{
				id: 2,
				title: 'Attempted Murder of a Peace Officer',
				description: 'This is something that should describe what the charge is',
				type: 2,
				fine: 20000,
				jail: 200,
			},
			{
				id: 3,
				title: 'Attempted Murder of a Government Official',
				description: 'This is something that should describe what the charge is',
				type: 3,
				fine: 20000,
				jail: 200,
			},
			{
				id: 4,
				title: 'First Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 1,
				fine: 20000,
				jail: 200,
			},
			{
				id: 5,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 2,
				fine: 20000,
				jail: 200,
			},
			{
				id: 6,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 3,
				fine: 20000,
				jail: 200,
			},
			{
				id: 7,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 1,
				fine: 20000,
				jail: 200,
			},
			{
				id: 8,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 2,
				fine: 20000,
				jail: 200,
			},
			{
				id: 9,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 3,
				fine: 20000,
				jail: 200,
			},
			{
				id: 10,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 1,
				fine: 20000,
				jail: 200,
			},
			{
				id: 11,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 2,
				fine: 20000,
				jail: 200,
			},
			{
				id: 12,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 3,
				fine: 20000,
				jail: 200,
			},
			{
				id: 13,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 1,
				fine: 20000,
				jail: 200,
			},
			{
				id: 14,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 2,
				fine: 20000,
				jail: 200,
			},
			{
				id: 15,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 3,
				fine: 20000,
				jail: 200,
			},
			{
				id: 16,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 1,
				fine: 20000,
				jail: 200,
			},
			{
				id: 17,
				title: 'Second Degree Murder',
				description: 'This is something that should describe what the charge is',
				type: 2,
				fine: 20000,
				jail: 200,
			},
		],
		// bolos: [
		// 	{
		// 		id: 1,
		// 		title: 'Test BOLO Title',
		// 		time: Date.now(),
		// 		author: {
		// 			Char: '6088b90c93a7b379e0c83ef2',
		// 			First: 'Testy',
		// 			Last: 'McGoo',
		// 			Callsign: 404,
		// 		},
		// 		type: 'user',
		// 		summary: 'This is a summary, I guess',
		// 		description: 'This is a long description of the event',
		// 	},
		// 	{
		// 		id: 2,
		// 		title: 'Test BOLO Title',
		// 		time: Date.now(),
		// 		author: {
		// 			Char: '6088b90c93a7b379e0c83ef2',
		// 			First: 'Testy',
		// 			Last: 'McGoo',
		// 			Callsign: 404,
		// 		},
		// 		type: 'car',
		// 		summary: 'This is a summary, I guess',
		// 		description: 'This is a long description of the event',
		// 	},
		// ],
		// warrants: Array(),
		// permissions: [
		// 	{
		// 		label: 'Police Doors',
		// 		value: 'police_doors',
		// 	},
		// 	{
		// 		label: 'EMS Doors',
		// 		value: 'ems_doors',
		// 	},
		// 	{
		// 		label: 'Generic Doors',
		// 		value: 'generic_doors',
		// 	},
		// 	{
		// 		label: 'Police Cars',
		// 		value: 'police_cars_0',
		// 	},
		// 	{
		// 		label: 'Police Cars I',
		// 		value: 'police_cars_1',
		// 	},
		// 	{
		// 		label: 'Police Cars II',
		// 		value: 'police_cars_2',
		// 	},
		// 	{
		// 		label: 'Police Cars III',
		// 		value: 'police_cars_3',
		// 	},
		// 	{
		// 		label: 'Police Cars IV',
		// 		value: 'police_cars_4',
		// 	},
		// 	{
		// 		label: 'Investigation',
		// 		value: 'police_investigation',
		// 	},
		// 	{
		// 		label: 'LSPD Supervisor',
		// 		value: 'lspd_supervisor',
		// 	},
		// 	{
		// 		label: 'LSPD High Command',
		// 		value: 'lspd_hc',
		// 	},
		// 	{
		// 		label: 'BCSO Supervisor',
		// 		value: 'bcso_supervisor',
		// 	},
		// 	{
		// 		label: 'BCSO High Command',
		// 		value: 'bcso_hc',
		// 	},
		// 	{
		// 		label: 'BCSO Supervisor',
		// 		value: 'bcso_supervisor',
		// 	},
		// 	{
		// 		label: 'LSSD High Command',
		// 		value: 'lssd_hc',
		// 	},
		// 	{
		// 		label: 'SASP Supervisor',
		// 		value: 'sasp_supervisor',
		// 	},
		// 	{
		// 		label: 'SASP High Command',
		// 		value: 'sasp_hc',
		// 	},
		// 	{
		// 		label: 'DOJ High Command',
		// 		value: 'leo_hc',
		// 	},
		// ],
		// qualifications: [
		// 	{
		// 		label: 'Field Training Officer',
		// 		value: 'fto',
		// 	},
		// 	{
		// 		label: 'Air 1',
		// 		value: 'air1',
		// 	},
		// 	{
		// 		label: 'Pursuit Interceptor',
		// 		value: 'pursuit',
		// 	},
		// 	{
		// 		label: 'Tactical Response',
		// 		value: 'swat',
		// 	},
		// ],
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
							? Object.prototype.toString.call(state.data[action.payload.type]) == '[object Array]'
								? action.payload.first
									? [action.payload.data, ...state.data[action.payload.type]]
									: [...state.data[action.payload.type], action.payload.data]
								: action.payload.key
								? {
										...state.data[action.payload.type],
										[action.payload.key]: action.payload.data,
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
						Object.prototype.toString.call(state.data[action.payload.type]) == '[object Array]'
							? state.data[action.payload.type].map((data) =>
									data.id == action.payload.id ? { ...action.payload.data } : data,
							  )
							: (state.data[action.payload.type] = action.payload.key
									? {
											...state.data[action.payload.type],
											[action.payload.id]: {
												...state.data[action.payload.type][action.payload.id],
												[action.payload.key]: action.payload.data,
											},
									  }
									: {
											...state.data[action.payload.type],
											[action.payload.id]: action.payload.data,
									  }),
				},
			};
		case 'REMOVE_DATA':
			return {
				...state,
				data: {
					...state.data,
					[action.payload.type]:
						Object.prototype.toString.call(state.data[action.payload.type]) == '[object Array]'
							? state.data[action.payload.type].filter((data) => {
									return Object.prototype.toString.call(data) == '[object Object]'
										? action.payload.key
											? data[action.payload.key] != action.payload.id
											: data.id != action.payload.id
										: data != action.payload.id;
							  })
							: (state.data[action.payload.type] = Object.keys(state.data[action.payload.type]).reduce(
									(result, key) => {
										if (key != action.payload.id) {
											result[key] = state.data[action.payload.type][key];
										}
										return result;
									},
									{},
							  )),
				},
			};
		case 'LOGOUT':
			return {
				...initialState,
			};
		case 'JOB_LOGOUT':
		case 'JOB_LOGIN':
			return {
				...state,
				data: {
					...state.data,
					homeLastFetch: 0,
				},
			};
		default:
			return state;
	}
};
