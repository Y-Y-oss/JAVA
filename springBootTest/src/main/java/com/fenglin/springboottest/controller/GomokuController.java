package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.common.BusinessException;
import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.entity.Friend;
import com.fenglin.springboottest.entity.GomokuGame;
import com.fenglin.springboottest.mapper.FriendMapper;
import com.fenglin.springboottest.mapper.GomokuGameMapper;
import com.fenglin.springboottest.service.AuthService;
import com.fenglin.springboottest.util.JwtUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 五子棋在线对弈接口（邀请好友，双端轮询同步）
 *
 * <pre>
 * 1. 邀请好友对弈  ：POST /api/gomoku/invite {friendId, color}   （color: black/white，需登录且必须是好友）
 * 2. 我的对局列表  ：GET  /api/gomoku/my                          （含 等我接受/我发的邀请/对弈中/已结束）
 * 3. 接受邀请      ：POST /api/gomoku/{id}/accept                 （被邀请人）
 * 4. 拒绝邀请      ：POST /api/gomoku/{id}/decline                （双方，未开始时可拒）
 * 5. 对局详情      ：GET  /api/gomoku/{id}                        （参战双方轮询用）
 * 6. 落子          ：POST /api/gomoku/{id}/move {x, y}            （校验轮次/空位，服务端判胜）
 * 7. 认输          ：POST /api/gomoku/{id}/resign                 （对弈中可认输）
 * </pre>
 */
@Slf4j
@RestController
@RequestMapping("/api/gomoku")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class GomokuController {

    private static final int SIZE = 15;
    private static final int STATUS_WAITING = 0;
    private static final int STATUS_PLAYING = 1;
    private static final int STATUS_FINISHED = 2;

    @Autowired
    private AuthService authService;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private GomokuGameMapper gameMapper;

    @Autowired
    private FriendMapper friendMapper;

    private String resolveToken(String authorization) {
        return authorization == null ? "" : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
    }

    private Long requireUserId(String authorization) {
        String token = resolveToken(authorization);
        if (!StringUtils.hasText(token)) {
            throw new BusinessException(401, "未携带登录凭证，请重新登录");
        }
        authService.checkRole(token);
        return jwtUtil.getUserId(token);
    }

    // ============================ 1. 邀请好友对弈 ============================

    @PostMapping("/invite")
    public R<Map<String, Object>> invite(@RequestHeader(value = "Authorization", required = false) String authorization,
                                         @RequestBody Map<String, Object> body) {
        Long me = requireUserId(authorization);
        Long friendId = body == null || body.get("friendId") == null ? null : Long.valueOf(String.valueOf(body.get("friendId")));
        String color = body == null || body.get("color") == null ? "black" : String.valueOf(body.get("color"));
        if (friendId == null) {
            throw new BusinessException("请选择要邀请的好友");
        }
        if (friendId.equals(me)) {
            throw new BusinessException("不能邀请自己对弈");
        }
        if (!"black".equals(color) && !"white".equals(color)) {
            throw new BusinessException("执子颜色只能是 black 或 white");
        }

        // 必须是好友才能邀请对弈
        Long rel = friendMapper.selectCount(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getUserId, me).eq(Friend::getFriendId, friendId).eq(Friend::getStatus, 1));
        if (rel == 0) {
            throw new BusinessException("只能邀请已验证的好友对弈");
        }

        // 同一对还没结束就别重复发
        Long dup = gameMapper.selectCount(new LambdaQueryWrapper<GomokuGame>()
                .eq(GomokuGame::getHostUserId, me)
                .eq(GomokuGame::getGuestUserId, friendId)
                .ne(GomokuGame::getStatus, STATUS_FINISHED));
        if (dup > 0) {
            throw new BusinessException("已有等待中/进行中的对局，先完成或拒绝它");
        }

        GomokuGame game = new GomokuGame();
        boolean meBlack = "black".equals(color);
        game.setBlackUserId(meBlack ? me : friendId);
        game.setWhiteUserId(meBlack ? friendId : me);
        game.setHostUserId(me);
        game.setGuestUserId(friendId);
        game.setStatus(STATUS_WAITING);
        game.setBoard(stringRepeat('0', SIZE * SIZE));
        game.setTurn(1); // 黑先
        game.setWinner(0);
        gameMapper.insert(game);
        log.info("五子棋邀请 me={}, friend={}, myColor={}", me, friendId, color);

        Map<String, Object> detail = gameMapper.selectGameDetail(game.getId());
        return R.ok("邀请已发送，等待好友接受", detail == null ? Map.of("id", game.getId()) : camelKeys(detail));
    }

    // ============================ 2. 我的对局列表 ============================

    @GetMapping("/my")
    public R<Map<String, Object>> my(@RequestHeader(value = "Authorization", required = false) String authorization) {
        Long me = requireUserId(authorization);
        List<Map<String, Object>> all = gameMapper.selectMyGames(me).stream()
                .map(this::camelKeys)
                .collect(Collectors.toList());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("toAccept", all.stream().filter(g -> num(g.get("status")) == STATUS_WAITING
                && num(g.get("guestUserId")) == me).collect(Collectors.toList()));
        data.put("waiting", all.stream().filter(g -> num(g.get("status")) == STATUS_WAITING
                && num(g.get("hostUserId")) == me).collect(Collectors.toList()));
        data.put("playing", all.stream().filter(g -> num(g.get("status")) == STATUS_PLAYING).collect(Collectors.toList()));
        data.put("finished", all.stream().filter(g -> num(g.get("status")) == STATUS_FINISHED).collect(Collectors.toList()));
        return R.ok("查询成功", data);
    }

    // ============================ 3. 接受邀请 ============================

    @PostMapping("/{id}/accept")
    public R<Map<String, Object>> accept(@RequestHeader(value = "Authorization", required = false) String authorization,
                                         @PathVariable("id") Long id) {
        Long me = requireUserId(authorization);
        GomokuGame game = requireGame(id, me);
        if (num(game.getStatus()) != STATUS_WAITING) {
            throw new BusinessException("该邀请已失效");
        }
        if (num(game.getGuestUserId()) != me) {
            throw new BusinessException(403, "只有被邀请人才能接受");
        }
        game.setStatus(STATUS_PLAYING);
        gameMapper.updateById(game);
        log.info("五子棋邀请接受 gameId={}, guest={}", id, me);
        return R.ok("对弈开始，黑方先手", camelKeys(gameMapper.selectGameDetail(id)));
    }

    // ============================ 4. 拒绝邀请 ============================

    @PostMapping("/{id}/decline")
    public R<Map<String, Object>> decline(@RequestHeader(value = "Authorization", required = false) String authorization,
                                          @PathVariable("id") Long id) {
        Long me = requireUserId(authorization);
        GomokuGame game = requireGame(id, me);
        if (num(game.getStatus()) != STATUS_WAITING) {
            throw new BusinessException("该邀请已失效");
        }
        gameMapper.deleteById(id);
        return R.ok("已拒绝对弈邀请", new LinkedHashMap<>());
    }

    // ============================ 5. 对局详情 ============================

    @GetMapping("/{id}")
    public R<Map<String, Object>> detail(@RequestHeader(value = "Authorization", required = false) String authorization,
                                         @PathVariable("id") Long id) {
        Long me = requireUserId(authorization);
        requireGame(id, me);
        return R.ok("查询成功", camelKeys(gameMapper.selectGameDetail(id)));
    }

    // ============================ 6. 落子 ============================

    @PostMapping("/{id}/move")
    public R<Map<String, Object>> move(@RequestHeader(value = "Authorization", required = false) String authorization,
                                       @PathVariable("id") Long id,
                                       @RequestBody Map<String, Object> body) {
        Long me = requireUserId(authorization);
        GomokuGame game = requireGame(id, me);
        if (num(game.getStatus()) != STATUS_PLAYING) {
            throw new BusinessException("对局不在进行中");
        }
        if (num(game.getWinner()) != 0) {
            throw new BusinessException("对局已结束");
        }

        int myColor = num(game.getBlackUserId()) == me ? 1 : 2;
        if (num(game.getTurn()) != myColor) {
            throw new BusinessException("还没轮到你落子");
        }

        int x, y;
        try {
            x = Integer.parseInt(String.valueOf(body.get("x")));
            y = Integer.parseInt(String.valueOf(body.get("y")));
        } catch (Exception e) {
            throw new BusinessException("落子坐标不正确");
        }
        if (x < 0 || y < 0 || x >= SIZE || y >= SIZE) {
            throw new BusinessException("落子坐标超出棋盘");
        }

        String board = game.getBoard();
        int idx = y * SIZE + x;
        if (board.charAt(idx) != '0') {
            throw new BusinessException("这个位置已经有棋子了");
        }

        StringBuilder sb = new StringBuilder(board);
        sb.setCharAt(idx, (char) ('0' + myColor));
        game.setBoard(sb.toString());
        game.setLastMoveX(x);
        game.setLastMoveY(y);

        if (checkWin(sb.toString(), x, y, myColor)) {
            game.setWinner(myColor);
            game.setStatus(STATUS_FINISHED);
        } else if (!sb.toString().contains("0")) {
            game.setWinner(3); // 棋盘下满，平局
            game.setStatus(STATUS_FINISHED);
        } else {
            game.setTurn(myColor == 1 ? 2 : 1);
        }
        gameMapper.updateById(game);
        return R.ok("落子成功", camelKeys(gameMapper.selectGameDetail(id)));
    }

    // ============================ 7. 认输 ============================

    @PostMapping("/{id}/resign")
    public R<Map<String, Object>> resign(@RequestHeader(value = "Authorization", required = false) String authorization,
                                         @PathVariable("id") Long id) {
        Long me = requireUserId(authorization);
        GomokuGame game = requireGame(id, me);
        if (num(game.getStatus()) != STATUS_PLAYING) {
            throw new BusinessException("对局不在进行中");
        }
        int myColor = num(game.getBlackUserId()) == me ? 1 : 2;
        game.setWinner(myColor == 1 ? 2 : 1);
        game.setStatus(STATUS_FINISHED);
        gameMapper.updateById(game);
        return R.ok("已认输", camelKeys(gameMapper.selectGameDetail(id)));
    }

    // ============================ 私有工具 ============================

    private GomokuGame requireGame(Long id, Long me) {
        GomokuGame game = gameMapper.selectById(id);
        if (game == null) {
            throw new BusinessException("对局不存在或已被删除");
        }
        boolean in = num(game.getBlackUserId()) == me || num(game.getWhiteUserId()) == me
                || num(game.getHostUserId()) == me || num(game.getGuestUserId()) == me;
        if (!in) {
            throw new BusinessException(403, "你不在这一局里");
        }
        return game;
    }

    /** 服务端判胜：以 (x,y) 为最后一手，四方向连子 >=5 即胜（棋盘字符 '0'+颜色值） */
    private boolean checkWin(String board, int x, int y, int color) {
        char stone = (char) ('0' + color);
        int[][] dirs = {{1, 0}, {0, 1}, {1, 1}, {1, -1}};
        for (int[] d : dirs) {
            int count = 1;
            for (int s = 1; s < 5; s++) {
                int nx = x + d[0] * s, ny = y + d[1] * s;
                if (nx < 0 || ny < 0 || nx >= SIZE || ny >= SIZE || charAt(board, nx, ny) != stone) break;
                count++;
            }
            for (int s = 1; s < 5; s++) {
                int nx = x - d[0] * s, ny = y - d[1] * s;
                if (nx < 0 || ny < 0 || nx >= SIZE || ny >= SIZE || charAt(board, nx, ny) != stone) break;
                count++;
            }
            if (count >= 5) return true;
        }
        return false;
    }

    private char charAt(String board, int x, int y) {
        return board.charAt(y * SIZE + x);
    }

    private String stringRepeat(char c, int n) {
        StringBuilder sb = new StringBuilder(n);
        for (int i = 0; i < n; i++) sb.append(c);
        return sb.toString();
    }

    private int num(Object v) {
        return v == null ? -1 : ((Number) v).intValue();
    }

    private Map<String, Object> camelKeys(Map<String, Object> row) {
        Map<String, Object> m = new LinkedHashMap<>();
        row.forEach((k, v) -> {
            String[] parts = k.split("_");
            StringBuilder sb = new StringBuilder(parts[0]);
            for (int i = 1; i < parts.length; i++) {
                sb.append(Character.toUpperCase(parts[i].charAt(0))).append(parts[i].substring(1));
            }
            m.put(sb.toString(), v);
        });
        return m;
    }
}
