using SimpleChess.Game;
using SimpleChess.Game.Moves;

// This namespace is used to find the default card image and sound assets in your pck:
// ie: res://TestMod/Cards/Banish[.wav,.png,Sound.tres]
namespace ChessTestMod.TestMod.Cards;

// Various types of cards exist with prebuilt interaction handlers
public record Banish : PieceTargettingCard
{
    // A few mandatory overrides
    public override string Symbol => "🫥";
    public override CardType Type => CardType.Action;
    public override string Title => "Banish";
    public override LifecycleHint LifecycleHint => LifecycleHint.Instant;
    public override string RichDescription => "[i]Here's a quote about banishment.[/i]\n\n[b]Banish[/b] a piece.";

    // And some additional ones that are useful
    public override Rarity Rarity => Rarity.Brilliant;

    // Is there a valid representation for the move given this information & intent?
    // This represents the mutation to the game eg: {cardid, pieceid, ...minor data }
    public override PlayCardOnPiece? GetMove(ChessGame game, Piece piece)
    {
        if (piece.IsKingLike) return null;
        var basicMove = GetBasicMove(game, piece, new Notation() { Action = Symbol, Target = piece.Description });
        return basicMove with { EndsTurn = true };
    }

    // Do the actual work of changing the game to represent the move
    public override ChessGame Apply(ChessGame game, Piece piece)
        => game.RemovePiece(piece.Identity, "banished");
}