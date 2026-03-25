import {
	APP_RESET,
	SET_CHARACTERS,
	CREATE_CHARACTER,
	DELETE_CHARACTER,
	SELECT_CHARACTER,
	DESELECT_CHARACTER,
	SET_DATA,
	UPDATE_PLAYED,
} from '../../actions/types';

export const initialState = {
	characters:
		process.env.NODE_ENV == 'production'
			? []
			: [
					{
						SID: 1,
						ID: '606e8a3c8144f19ec0aeeece',
						User: '606c22a749c1c980e8289b35',
						First: 'Test',
						Last: 'Test',
						DOB: '1991-01-01T07:59:59.000Z',
						Phone: '046-504-2706',
						LastPlayed: 1618051388000,
						Gender: 0,
						Armor: 100,
						HP: 200,
						JobDuty: false,
						Job: {
							Id: 'police',
							Name: 'Police',
							Workplace: {
								Id: 'lspd',
								Name: 'Los Santos Police Department',
							},
							Grade: {
								Id: 'chief',
								Name: 'Chief',
							},
						},
					},
					{
						SID: 2,
						ID: '606e8a3c8144f19ec0aeeecf',
						User: '606c22a749c1c980e8289b35',
						First: 'Test',
						Last: 'Test',
						DOB: '1991-01-01T07:59:59.000Z',
						Phone: '046-504-2706',
						LastPlayed: 1618051388000,
						Gender: 0,
						Armor: 100,
						HP: 200,
						JobDuty: false,
						Job: {
							Id: 'police',
							Name: 'Police',
							Workplace: {
								Id: 'lspd',
								Name: 'Los Santos Police Department',
							},
							Grade: {
								Id: 'chief',
								Name: 'Chief',
							},
						},
					},
			  ],
	changelog: null,
	motd: process.env.NODE_ENV == 'production' ? null : 'This is a test :)',
	selected: {
		SID: 1,
		ID: '606e8a3c8144f19ec0aeeece',
		User: '606c22a749c1c980e8289b35',
		First: 'Test',
		Last: 'Test',
		DOB: '1991-01-01T07:59:59.000Z',
		Phone: '046-504-2706',
		LastPlayed: 1618051388000,
		Gender: 0,
		Armor: 100,
		HP: 200,
		JobDuty: false,
		Job: {
			Id: 'police',
			Name: 'Police',
			Workplace: {
				Id: 'lspd',
				Name: 'Los Santos Police Department',
			},
			Grade: {
				Id: 'chief',
				Name: 'Chief',
			},
		},
	},
	characterLimit: 3,
};

const charReducer = (state = initialState, action) => {
	switch (action.type) {
		case SET_CHARACTERS:
			return { ...state, characters: action.payload, selected: null };
		case CREATE_CHARACTER:
			state.characters.push(action.payload.character);
			return state;
		case DELETE_CHARACTER:
			return {
				...state,
				characters: state.characters.filter(
					(c) => c.ID != action.payload.id,
				),
			};
		case SELECT_CHARACTER:
			return { ...state, selected: action.payload.character };
		case DESELECT_CHARACTER:
			return { ...state, selected: null };
		case SET_DATA:
			return {
				...state,
				characters: action.payload.characters,
				changelog: action.payload.changelog,
				motd: action.payload.motd,
				characterLimit: action.payload.characterLimit,
			};
		case UPDATE_PLAYED:
			return {
				...state,
				characters: state.characters.map((char) =>
					char.ID === state.selected.ID
						? { ...char, LastPlayed: Date.now() }
						: char,
				),
			};
		case APP_RESET:
			return {
				...initialState,
				hidden: false,
			};
		default:
			return state;
	}
};

export default charReducer;
