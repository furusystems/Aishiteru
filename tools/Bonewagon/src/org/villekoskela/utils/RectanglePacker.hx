/**
 * Rectangle Packer v1.3.0
 *
 * Copyright 2012 Ville Koskela. All rights reserved.
 *
 * Email: ville@villekoskela.org
 * Blog: http://villekoskela.org
 * Twitter: @villekoskelaorg
 *
 * You may redistribute, use and/or modify this source code freely
 * but this copyright statement must not be removed from the source files.
 *
 * The package structure of the source code must remain unchanged.
 * Mentioning the author in the binary distributions is highly appreciated.
 *
 * If you use this utility it would be nice to hear about it so feel free to drop
 * an email.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. *
 *
 */
package org.villekoskela.utils
{
    import flash.geom.Rectangle;

    /**
     * Class used to pack rectangles within container rectangle with close to optimal solution.
     */
    class RectanglePacker
    {
        public static var VERSION:String = "1.3.0";

        var mWidth:Int = 0;
        var mHeight:Int = 0;
        var mPadding:Int = 8;

        var mPackedWidth:Int = 0;
        var mPackedHeight:Int = 0;

        var mInsertList:Array = [];

        var mInsertedRectangles:Array<IntegerRectangle> = new Array<IntegerRectangle>();
        var mFreeAreas:Array<IntegerRectangle> = new Array<IntegerRectangle>();
        var mNewFreeAreas:Array<IntegerRectangle> = new Array<IntegerRectangle>();

        var mOutsideRectangle:IntegerRectangle;

        var mSortableSizeStack:Array<SortableSize> = new Array<SortableSize>();
        var mRectangleStack:Array<IntegerRectangle> = new Array<IntegerRectangle>();

        public function get rectangleCount():Int { return mInsertedRectangles.length; }

        public function get packedWidth():Int { return mPackedWidth; }
        public function get packedHeight():Int { return mPackedHeight; }

        public function get padding():Int { return mPadding; }

        /**
         * Constructs new rectangle packer
         * @param width the width of the main rectangle
         * @param height the height of the main rectangle
         */
        public function RectanglePacker(width:Int, height:Int, padding:Int = 0)
        {
            mOutsideRectangle = new IntegerRectangle(width + 1, height + 1, 0, 0);
            reset(width, height, padding);
        }

        /**
         * Resets the rectangle packer with given dimensions
         * @param width
         * @param height
         */
        public function reset(width:Int, height:Int, padding:Int = 0)
        {
            while (mInsertedRectangles.length)
            {
                freeRectangle(mInsertedRectangles.pop());
            }

            while (mFreeAreas.length)
            {
                freeRectangle(mFreeAreas.pop());
            }

            mWidth = width;
            mHeight = height;

            mPackedWidth = 0;
            mPackedHeight = 0;

            mFreeAreas[0] = allocateRectangle(0, 0, mWidth, mHeight);

            while (mInsertList.length)
            {
                freeSize(mInsertList.pop());
            }

            mPadding = padding;
        }

        /**
         * Gets the position of the rectangle in given index in the main rectangle
         * @param index the index of the rectangle
         * @param rectangle an instance where to set the rectangle's values
         * @return
         */
        public function getRectangle(index:Int, rectangle:Rectangle):Rectangle
        {
            var inserted:IntegerRectangle = mInsertedRectangles[index];
            if (rectangle)
            {
                rectangle.x = inserted.x;
                rectangle.y = inserted.y;
                rectangle.width = inserted.width;
                rectangle.height = inserted.height;
                return rectangle;
            }

            return new Rectangle(inserted.x, inserted.y, inserted.width, inserted.height);
        }

        /**
         * Gets the original id for the inserted rectangle in given index
         * @param index
         * @return
         */
        public function getRectangleId(index:Int):int
        {
            var inserted:IntegerRectangle = mInsertedRectangles[index];
            return inserted.id;
        }

        /**
         * Add a rectangle to be packed into the packer
         * @width the width of inserted rectangle
         * @height the height of inserted rectangle
         * @id the identifier for this rectangle
         * @return true if inserted successfully
         */
        public function insertRectangle(width:Int, height:Int, id:Int)
        {
            var sortableSize:SortableSize = allocateSize(width, height, id);
            mInsertList.push(sortableSize);
        }

        /**
         * Packs the rectangles inserted
         * @param sort boolean defining whether to sort the inserted rectangles before packing
         * @return the number of the packed rectangles
         */
        public function packRectangles(sort:Bool = true):int
        {
            if (sort)
            {
                mInsertList.sortOn("width", Array.NUMERIC);
            }

            while (mInsertList.length > 0)
            {
                var sortableSize:SortableSize = mInsertList.pop() as SortableSize;
                var width:Int = sortableSize.width;
                var height:Int = sortableSize.height;

                var index:Int = getFreeAreaIndex(width, height);
                if (index >= 0)
                {
                    var freeArea:IntegerRectangle = mFreeAreas[index];
                    var target:IntegerRectangle = allocateRectangle(freeArea.x, freeArea.y, width, height);
                    target.id = sortableSize.id;

                    // Generate the new free areas, these are parts of the old ones intersected or touched by the target
                    generateNewFreeAreas(target, mFreeAreas, mNewFreeAreas);

                    while (mNewFreeAreas.length > 0)
                    {
                        mFreeAreas[mFreeAreas.length] = mNewFreeAreas.pop();
                    }

                    mInsertedRectangles[mInsertedRectangles.length] = target;
                    if (target.right > mPackedWidth)
                    {
                        mPackedWidth = target.right;
                    }
                    if (target.bottom > mPackedHeight)
                    {
                        mPackedHeight = target.bottom;
                    }
                }

                freeSize(sortableSize);
            }

            return rectangleCount;
        }

        /**
         * Removes rectangles from the filteredAreas that are sub rectangles of any rectangle in areas.
         * @param areas rectangles from which the filtering is performed
         */
        function filterSelfSubAreas(areas:Array<IntegerRectangle>)
        {
            for (var i:Int = areas.length - 1; i >= 0; i--)
            {
                var filtered:IntegerRectangle = areas[i];
                for (var j:Int = areas.length - 1; j >= 0; j--)
                {
                    if (i != j)
                    {
                        var area:IntegerRectangle = areas[j];
                        if (filtered.x >= area.x && filtered.y >= area.y &&
                            filtered.right <= area.right && filtered.bottom <= area.bottom)
                        {
                            freeRectangle(filtered);
                            var topOfStack:IntegerRectangle = areas.pop();
                            if (i <areas.length)
                            {
                                // Move the one on the top to the freed position
                                areas[i] = topOfStack;
                            }
                            break;
                        }
                    }
                }
            }
        }

        /**
         * Checks what areas the given rectangle intersects, removes those areas and
         * returns the list of new areas those areas are divided into
         * @param target the new rectangle that is dividing the areas
         * @param areas the areas to be divided
         * @return list of new areas
         */
        function generateNewFreeAreas(target:IntegerRectangle, areas:Array<IntegerRectangle>, results:Array<IntegerRectangle>)
        {
            // Increase dimensions by one to get the areas on right / bottom this rectangle touches
            // Also add the padding here
            var x:Int = target.x;
            var y:Int = target.y;
            var right:Int = target.right + 1 + mPadding;
            var bottom:Int = target.bottom + 1 + mPadding;

            var targetWithPadding:IntegerRectangle = null;
            if (mPadding == 0)
            {
                targetWithPadding = target;
            }

            for (var i:Int = areas.length - 1; i >= 0; i--)
            {
                var area:IntegerRectangle = areas[i];
                if (!(x >= area.right || right <= area.x || y >= area.bottom || bottom <= area.y))
                {
                    if (!targetWithPadding)
                    {
                        targetWithPadding = allocateRectangle(target.x, target.y, target.width + mPadding, target.height + mPadding);
                    }

                    generateDividedAreas(targetWithPadding, area, results);
                    var topOfStack:IntegerRectangle = areas.pop();
                    if (i < areas.length)
                    {
                        // Move the one on the top to the freed position
                        areas[i] = topOfStack;
                    }
                }
            }

            if (targetWithPadding && targetWithPadding != target)
            {
                freeRectangle(targetWithPadding);
            }

            filterSelfSubAreas(results);
        }

        /**
         * Divides the area into new sub areas around the divider.
         * @param divider rectangle that intersects the area
         * @param area rectangle to be divided into sub areas around the divider
         * @param results vector for the new sub areas around the divider
         */
        function generateDividedAreas(divider:IntegerRectangle, area:IntegerRectangle, results:Array<IntegerRectangle>)
        {
            var count:Int = 0;
            var rightDelta:Int = area.right - divider.right;
            if (rightDelta > 0)
            {
                results[results.length] = allocateRectangle(divider.right, area.y, rightDelta, area.height);
                count++;
            }

            var leftDelta:Int = divider.x - area.x;
            if (leftDelta > 0)
            {
                results[results.length] = allocateRectangle(area.x, area.y, leftDelta, area.height);
                count++;
            }

            var bottomDelta:Int = area.bottom - divider.bottom;
            if (bottomDelta > 0)
            {
                results[results.length] = allocateRectangle(area.x, divider.bottom, area.width, bottomDelta);
                count++;
            }

            var topDelta:Int = divider.y - area.y;
            if (topDelta > 0)
            {
                results[results.length] = allocateRectangle(area.x, area.y, area.width, topDelta);
                count++;
            }

            if (count == 0 && (divider.width < area.width || divider.height < area.height))
            {
                // Only touching the area, store the area itself
                results[results.length] = area;
            }
            else
            {
                freeRectangle(area);
            }
        }

        /**
         * Gets the index of the best free area for the given rectangle
         * @width the width of inserted rectangle
         * @height the height of inserted rectangle
         * @return index of the best free area or -1 if no suitable free area available
         */
        function getFreeAreaIndex(width:Int, height:Int):int
        {
            var best:IntegerRectangle = mOutsideRectangle;
            var index:Int = -1;

            var paddedWidth:Int = width + mPadding;
            var paddedHeight:Int = height + mPadding;

            var count:Int = mFreeAreas.length;
            for (var i:Int = count - 1; i >= 0; i--)
            {
                var free:IntegerRectangle = mFreeAreas[i];
                if (free.x < mPackedWidth || free.y < mPackedHeight)
                {
                    // Within the packed area, padding required
                    if (free.x < best.x && paddedWidth <= free.width && paddedHeight <= free.height)
                    {
                        index = i;
                        if ((paddedWidth == free.width && free.width <= free.height && free.right < mWidth) ||
                                (paddedHeight == free.height && free.height <= free.width))
                        {
                            break;
                        }
                        best = free;
                    }
                }
                else
                {
                    // Outside the current packed area, no padding required
                    if (free.x < best.x && width <= free.width && height <= free.height)
                    {
                        index = i;
                        if ((width == free.width && free.width <= free.height && free.right < mWidth) ||
                                (height == free.height && free.height <= free.width))
                        {
                            break;
                        }
                        best = free;
                    }
                }
            }

            return index;
        }

        /**
         * Allocates new rectangle. If one available in stack uses that, otherwise new.
         * @param x
         * @param y
         * @param width
         * @param height
         * @return
         */
        function allocateRectangle(x:Int, y:Int, width:Int, height:Int):IntegerRectangle
        {
            if (mRectangleStack.length > 0)
            {
                var rectangle:IntegerRectangle = mRectangleStack.pop();
                rectangle.x = x;
                rectangle.y = y;
                rectangle.width = width;
                rectangle.height = height;
                rectangle.right = x + width;
                rectangle.bottom = y + height;

                return rectangle;
            }

            return new IntegerRectangle(x, y, width, height);
        }

        /**
         * Pushes the freed rectangle to rectangle stack. Make sure not to push same rectangle twice!
         * @param rectangle
         */
        function freeRectangle(rectangle:IntegerRectangle)
        {
            mRectangleStack[mRectangleStack.length] = rectangle;
        }

        /**
         * Allocates new sortable size instance. If one available in stack uses that, otherwise new.
         * @param width
         * @param height
         * @param id
         * @return
         */
        function allocateSize(width:Int, height:Int, id:Int):SortableSize
        {
            if (mSortableSizeStack.length > 0)
            {
                var size:SortableSize = mSortableSizeStack.pop();
                size.width = width;
                size.height = height;
                size.id = id;

                return size;
            }

            return new SortableSize(width, height, id);
        }

        /**
         * Pushes the freed sortable size to size stack. Make sure not to push same size twice!
         * @param size
         */
        function freeSize(size:SortableSize)
        {
            mSortableSizeStack[mSortableSizeStack.length] = size;
        }
    }
}
