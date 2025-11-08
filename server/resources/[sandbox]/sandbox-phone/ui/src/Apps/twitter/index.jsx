import React, { Fragment, useEffect, useMemo, useState } from 'react';
import { useSelector } from 'react-redux';
import { TextField, IconButton } from '@mui/material';
import { makeStyles } from '@mui/styles';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { throttle } from 'lodash';
import InfiniteScroll from 'react-infinite-scroll-component';
import { useNavigate } from 'react-router';

import Nui from '../../util/Nui';
import {
	AppContainer,
	Confirm,
	EventListener,
	Loader,
	Modal,
	AppInput,
} from '../../components';
import { useAlert, useAppData } from '../../hooks';
import Tweet from './Tweet';

const useStyles = makeStyles((theme) => ({
	editField: {
		marginBottom: 15,
		'&::-webkit-scrollbar': {
			width: 6,
		},
		'&::-webkit-scrollbar-thumb': {
			background: '#ffffff52',
		},
		'&::-webkit-scrollbar-thumb:hover': {
			background: '#1de9b6',
		},
		'&::-webkit-scrollbar-track': {
			background: 'transparent',
		},
	},
	inner: {
		position: 'relative',
		height: '100%',
	},
	preview: {
		maxWidth: 250,
		maxHeight: 250,
		width: '100%',
		height: '100%',
		margin: 'auto',
		display: 'block',
		padding: 16,
	},
	header: {
		background: '#00aced',
		fontSize: 20,
		padding: 15,
		lineHeight: '45px',
		height: 78,
	},
	tweetList: {
		padding: '8px 4px',
		height: '100%',
		width: '100%',
		display: 'flex',
		flexDirection: 'column',
		overflowX: 'hidden',
		overflowY: 'auto',
	},
}));

const testTweets = [
	{
		id: 1,
		author: {
			name: 'TestTesterson001',
			avatar: 'https://avatarfiles.alphacoders.com/453/45341.jpg',
		},
		image: {
			using: false,
			link: null,
		},
		time: 1618740407000,
		content:
			'@Arch #Arch https://i.imgur.com/OsHuv0I.jpg <script>alert("&")</script> ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in',
		likes: Array(),
	},
	{
		id: 2,
		author: {
			name: 'TestTesterson001',
			avatar: 'https://avatarfiles.alphacoders.com/453/45341.jpg',
		},
		image: {
			using: false,
			link: null,
		},
		time: 1618740407000,
		content:
			'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in',
		likes: Array(),
	},
	{
		id: 3,
		author: {
			name: 'TestTesterson001',
			avatar: 'https://avatarfiles.alphacoders.com/453/45341.jpg',
		},
		image: {
			using: false,
			link: null,
		},
		time: 1618740407000,
		content:
			'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in',
		likes: Array(),
	},
	{
		id: 4,
		author: {
			name: 'TestTesterson001',
			avatar: 'https://avatarfiles.alphacoders.com/453/45341.jpg',
		},
		image: {
			using: false,
			link: null,
		},
		time: 1618740407000,
		content:
			'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in',
		likes: Array(),
	},
	{
		id: 5,
		author: {
			name: 'TestTesterson001',
			avatar: 'https://avatarfiles.alphacoders.com/453/45341.jpg',
		},
		image: {
			using: false,
			link: null,
		},
		time: 1618740407000,
		content:
			'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in',
		likes: Array(),
	},
	{
		id: 6,
		author: {
			name: 'TestTesterson001',
			avatar: 'https://avatarfiles.alphacoders.com/453/45341.jpg',
		},
		image: {
			using: false,
			link: null,
		},
		time: 1618740407000,
		content:
			'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in',
		likes: Array(),
	},
	{
		id: 7,
		author: {
			name: 'TestTesterson001',
			avatar: 'https://avatarfiles.alphacoders.com/453/45341.jpg',
		},
		image: {
			using: false,
			link: null,
		},
		time: 1618740407000,
		content:
			'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in',
		likes: Array(),
	},
];

export default (props) => {
	const appData = useAppData('twitter');
	const classes = useStyles(appData);
	const navigate = useNavigate();
	const showAlert = useAlert();
	//const tweets = useSelector((state) => state.data.data.tweets);
	const player = useSelector((state) => state.data.data.player);

	//const pages = tweets ? Math.ceil(tweets.length / 20) : 0;
	const [loading, setLoading] = useState(false);

	const [tweetCount, setTweetCount] = useState(Array());
	const [tweets, setTweets] = useState([]);

	const [open, setOpen] = useState(false);
	const [state, setState] = useState({
		tweet: '',
		usingImg: false,
		imgLink: '',
	});
	const [pendingRetweet, setPendingRetweet] = useState(null);

	const fetchCount = useMemo(
		() =>
			throttle(async () => {
				try {
					let res = await (await Nui.send('Twitter:GetCount')).json();
					if (Boolean(res)) setTweetCount(res);
					else setTweetCount(0);
				} catch (err) {
					console.error(err);
				}
			}, 1000),
		[],
	);

	useEffect(() => {
		fetchCount();
		onLoadTweets();
	}, []);

	const onStateChange = (e) => {
		setState({
			...state,
			[e.target.name]: e.target.value,
		});
	};

	const toggleImage = () => {
		setState({
			...state,
			imgLink: '',
			usingImg: !state.usingImg,
		});
	};

	const onReply = (name) => {
		setState({
			...state,
			tweet: `@${name} `,
		});
		setOpen(true);
	};

	const confirmRetweet = (tweet) => {
		setPendingRetweet(tweet);
	};
	const onRetweet = async () => {
		let res = await sendTweet({
			...pendingRetweet,
			author: player.Profiles?.twitter?.name,
			content: `RESPAM: @${pendingRetweet.author.name} "${pendingRetweet.content}"`,
			time: Date.now() / 1000,
			retweet: pendingRetweet.id,
			likes: Array(),
		});
		setPendingRetweet(null);
		showAlert(res ? 'Respammed' : 'Unable to Respam');
	};

	const sendTweet = async (tweet) => {
		try {
			let res = await (await Nui.send('SendTweet', tweet)).json();

			if (res) {
				setOpen(false);
				setState({
					tweet: '',
					usingImg: false,
					imgLink: '',
				});
				return true;
			} else {
				return false;
			}
		} catch (err) {
			console.error(err);
			return false;
		}
	};

	const onCreate = async (e) => {
		let res = await sendTweet({
			time: Date.now() / 1000,
			content: state.tweet,
			image: {
				using: state.usingImg,
				link: state.imgLink,
			},
			likes: Array(),
		});
		setState({
			tweet: '',
			usingImg: false,
			imgLink: '',
		});
		setOpen(false);
		showAlert(res ? 'Spam Created' : 'Unable to Create Spam');
	};

	const onLoadTweets = async () => {
		try {
			setLoading(true);
			let res = await (
				await Nui.send('Twitter:GetTweets', tweets.length)
			).json();
			if (Boolean(res)) {
				setTweets([...tweets, ...res]);
			} else {
			}
			setLoading(false);
		} catch (err) {
			console.error(err);
		}
	};

	const onReceivedNewTweet = (tweet) => {
		setTweets([...tweets, tweet]);
		setTweetCount(tweetCount + 1);
	};

	const onClear = () => {
		setTweets([]);
	};

	const onRemoveTweetsFromAccount = ({ account, count }) => {
		setTweets([
			...tweets.filter((t) => t.SID != account && t.author != account),
		]);
		setTweetCount(count);
	};

	return (
		<EventListener
			event="REMOVE_ACCOUNT_TWEETS"
			onEvent={onRemoveTweetsFromAccount}
			state={{ tweets, tweetCount }}
		>
			<EventListener
				event="RECEIVED_NEW_TWEET"
				onEvent={onReceivedNewTweet}
				state={{ tweets, tweetCount }}
			>
				<EventListener
					event="CLEAR_TWEETS"
					onEvent={onClear}
					state={{ tweets, tweetCount }}
				>
					<AppContainer
						appId="twitter"
						actions={
							<Fragment>
								<IconButton
									onClick={() =>
										navigate('/apps/twitter/profile')
									}
								>
									<FontAwesomeIcon
										icon={['far', 'circle-user']}
									/>
								</IconButton>
								<IconButton
									onClick={() => setOpen(true)}
									disabled={!Boolean(player.Profiles?.twitter)}
								>
									<FontAwesomeIcon icon={['fas', 'plus']} />
								</IconButton>
							</Fragment>
						}
					>
						{loading && <Loader static text="Loading Spam" />}
						<div className={classes.tweetList} id="scrollableDiv">
							<InfiniteScroll
								dataLength={tweets.length}
								next={onLoadTweets}
								hasMore={
									(tweets?.length ?? 0) < (tweetCount ?? 0)
								}
								scrollableTarget="scrollableDiv"
								loader={<h4>Loading...</h4>}
								endMessage={
									<p style={{ textAlign: 'center' }}>
										<b>You've read all the spam, nice</b>
									</p>
								}
							>
								{tweets
									.sort((a, b) => b.time - a.time)
									.map((tweet) => {
										return (
											<Tweet
												key={tweet.id}
												tweet={tweet}
												rtcount={
													tweets.filter(
														(t) =>
															t.retweet ==
															tweet.id,
													).length
												}
												onReply={onReply}
												onRetweet={confirmRetweet}
											/>
										);
									})}
							</InfiniteScroll>
						</div>
						<Modal
							form
							open={open}
							title="Send New Spam"
							onClose={() => setOpen(false)}
							onAccept={onCreate}
							onDelete={toggleImage}
							submitLang="Send Spam"
							deleteLang={
								state.usingImg ? 'Remove Image' : 'Attach Image'
							}
							closeLang="Cancel"
						>
							<>
								<AppInput
									app={appData}
									className={classes.editField}
									label="Spam"
									name="tweet"
									type="text"
									fullWidth
									multiline
									required
									helperText={`${state.tweet.length} / 180 Characters`}
									value={state.tweet}
									onChange={onStateChange}
									inputProps={{
										maxLength: 180,
									}}
									InputLabelProps={{
										style: { fontSize: 20 },
									}}
								/>
								{state.usingImg && (
									<>
										{state.imgLink != '' && (
											<img
												src={state.imgLink}
												className={classes.preview}
											/>
										)}
										<AppInput
											app={appData}
											className={classes.editField}
											label="Image"
											name="imgLink"
											helperText="Imgur Links Only!"
											type="text"
											fullWidth
											required
											value={state.imgLink}
											onChange={onStateChange}
											InputLabelProps={{
												style: { fontSize: 20 },
											}}
										/>
									</>
								)}
							</>
						</Modal>
						<Confirm
							title="Respam?"
							open={pendingRetweet != null}
							confirm="Respam"
							decline="Cancel"
							onConfirm={onRetweet}
							onDecline={() => setPendingRetweet(null)}
						/>
					</AppContainer>
				</EventListener>
			</EventListener>
		</EventListener>
	);
};
